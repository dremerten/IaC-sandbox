terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

locals {
  name       = "${var.name_prefix}-${var.component}"
  bucket_arn = "arn:aws:s3:::${var.bucket_name}"
  tags = merge(var.tags, {
    component = var.component
    region    = var.region
  })
  subnet_ids = length(var.private_subnet_ids) > 0 ? var.private_subnet_ids : var.public_subnet_ids
  lambda_zip_base64 = "UEsDBBQAAAAIADVnPlxk0uNfQwAAAEEAAAAIAAAAaW5kZXguanNLrSjILyop1stIzEvJSS1SsFVILK7MS1bQ0FSwtVPQqFYoLkksKS12zk9JtVIwMjDQUUjKT6m0UlDPz1ZXqNW05gIAUEsBAhQDFAAAAAgANWc+XGTS419DAAAAQQAAAAgAAAAAAAAAAAAAAIABAAAAAGluZGV4LmpzUEsFBgAAAAABAAEANgAAAGkAAAAAAA=="
  sfn_definition = "{\"Comment\":\"Hello\",\"StartAt\":\"Hello\",\"States\":{\"Hello\":{\"Type\":\"Pass\",\"Result\":\"ok\",\"End\":true}}}"
  opensearch_base_raw   = join("", regexall("[a-z0-9-]", lower(local.name)))
  opensearch_base_trim  = trim(local.opensearch_base_raw, "-")
  opensearch_base_pre   = local.opensearch_base_trim != "" ? local.opensearch_base_trim : "demo"
  opensearch_base_alpha = length(regexall("^[a-z]", local.opensearch_base_pre)) > 0 ? local.opensearch_base_pre : "demo-${local.opensearch_base_pre}"
  opensearch_base       = substr(local.opensearch_base_alpha, 0, 25)
  opensearch_domain_name = "${local.opensearch_base}-os"
}

resource "terraform_data" "dynamodb_table" {
  count = var.enable ? 1 : 0

  input = {
    name      = "${local.name}-ddb"
    region    = var.region
    tags      = local.tags
    component = var.component
  }

  triggers_replace = {
    name      = "${local.name}-ddb"
    region    = var.region
    component = var.component
  }

  provisioner "local-exec" {
    command = <<-EOT
      exists="$(aws --endpoint-url "$LOCALSTACK_ENDPOINT" --region "${self.output.region}" dynamodb list-tables --query "TableNames[?@=='${self.output.name}'] | length(@)" --output text 2>/dev/null || echo 0)"
      if [ "$exists" != "1" ]; then
        aws --endpoint-url "$LOCALSTACK_ENDPOINT" --region "${self.output.region}" dynamodb create-table \
          --table-name "${self.output.name}" \
          --billing-mode PAY_PER_REQUEST \
          --attribute-definitions AttributeName=pk,AttributeType=S \
          --key-schema AttributeName=pk,KeyType=HASH \
          --tags Key=component,Value="${self.output.component}" Key=region,Value="${self.output.region}" >/dev/null 2>&1 || true
      fi
    EOT
  }

  provisioner "local-exec" {
    when = destroy
    command = <<-EOT
      aws --endpoint-url "$LOCALSTACK_ENDPOINT" --region "${self.output.region}" dynamodb delete-table --table-name "${self.output.name}" >/dev/null 2>&1 || true
    EOT
  }
}

resource "aws_sqs_queue" "this" {
  count = var.enable ? 1 : 0
  name  = "${local.name}-queue"
  tags  = local.tags
}

resource "aws_sns_topic" "this" {
  count = var.enable ? 1 : 0
  name  = "${local.name}-topic"
  tags  = local.tags
}

resource "aws_s3_object" "lambda_zip" {
  count          = var.enable && var.enable_lambda ? 1 : 0
  bucket         = var.bucket_name
  key            = "lambda/${local.name}.zip"
  content_base64 = local.lambda_zip_base64
  content_type   = "application/zip"
  tags           = local.tags
}

resource "aws_iam_role" "lambda" {
  count = var.enable && var.enable_lambda ? 1 : 0
  name  = "${local.name}-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  tags = local.tags
}

resource "aws_iam_role_policy" "lambda" {
  count = var.enable && var.enable_lambda ? 1 : 0
  role  = aws_iam_role.lambda[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_lambda_function" "this" {
  count         = var.enable && var.enable_lambda ? 1 : 0
  function_name = "${local.name}-lambda"
  role          = aws_iam_role.lambda[0].arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  s3_bucket     = var.bucket_name
  s3_key        = aws_s3_object.lambda_zip[0].key
  source_code_hash = sha256(local.lambda_zip_base64)
  tags          = local.tags
}

resource "aws_api_gateway_rest_api" "this" {
  count = var.enable ? 1 : 0
  name  = "${local.name}-api"
  tags  = local.tags
}

resource "aws_api_gateway_resource" "hello" {
  count       = var.enable ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.this[0].id
  parent_id   = aws_api_gateway_rest_api.this[0].root_resource_id
  path_part   = "hello"
}

resource "aws_api_gateway_method" "hello_get" {
  count         = var.enable ? 1 : 0
  rest_api_id   = aws_api_gateway_rest_api.this[0].id
  resource_id   = aws_api_gateway_resource.hello[0].id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "hello_get" {
  count       = var.enable ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.this[0].id
  resource_id = aws_api_gateway_resource.hello[0].id
  http_method = aws_api_gateway_method.hello_get[0].http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "hello_get" {
  count       = var.enable ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.this[0].id
  resource_id = aws_api_gateway_resource.hello[0].id
  http_method = aws_api_gateway_method.hello_get[0].http_method
  status_code = "200"
}

resource "aws_api_gateway_deployment" "this" {
  count       = var.enable ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.this[0].id
  triggers = {
    redeploy = sha1("hello")
  }
  depends_on = [aws_api_gateway_integration.hello_get]
}

resource "aws_api_gateway_stage" "this" {
  count         = var.enable ? 1 : 0
  rest_api_id   = aws_api_gateway_rest_api.this[0].id
  deployment_id = aws_api_gateway_deployment.this[0].id
  stage_name    = "dev"
}

resource "aws_cloudwatch_log_group" "this" {
  count             = var.enable ? 1 : 0
  name              = "/iac/${local.name}"
  retention_in_days = 7
  tags              = local.tags
}

resource "aws_cloudwatch_metric_alarm" "this" {
  count               = var.enable ? 1 : 0
  alarm_name          = "${local.name}-cpu-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_actions       = length(aws_sns_topic.this) > 0 ? [aws_sns_topic.this[0].arn] : []
  dimensions = {
    InstanceId = "i-00000000000000000"
  }
  tags = local.tags
}

resource "aws_ssm_parameter" "this" {
  count = var.enable ? 1 : 0
  name  = "/${local.name}/config/example"
  type  = "String"
  value = "example"
  tags  = local.tags
}

resource "aws_cloudwatch_event_rule" "this" {
  count               = var.enable ? 1 : 0
  name                = "${local.name}-rule"
  schedule_expression = "rate(5 minutes)"
  tags                = local.tags
}

resource "aws_cloudwatch_event_target" "this" {
  count = var.enable ? 1 : 0
  rule  = aws_cloudwatch_event_rule.this[0].name
  arn   = aws_sns_topic.this[0].arn
}

resource "aws_iam_role" "scheduler" {
  count = var.enable ? 1 : 0
  name  = "${local.name}-scheduler-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "scheduler.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  tags = local.tags
}

resource "aws_iam_role_policy" "scheduler" {
  count = var.enable ? 1 : 0
  role  = aws_iam_role.scheduler[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["sqs:SendMessage"]
        Resource = [aws_sqs_queue.this[0].arn]
      }
    ]
  })
}

resource "aws_scheduler_schedule" "this" {
  count               = var.enable ? 1 : 0
  name                = "${local.name}-schedule"
  schedule_expression = "rate(10 minutes)"
  flexible_time_window {
    mode = "OFF"
  }
  target {
    arn      = aws_sqs_queue.this[0].arn
    role_arn = aws_iam_role.scheduler[0].arn
  }
}

resource "aws_ses_email_identity" "this" {
  count = var.enable ? 1 : 0
  email = "noreply-${local.name}@example.com"
}

resource "aws_iam_role" "sfn" {
  count = var.enable ? 1 : 0
  name  = "${local.name}-sfn-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "states.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  tags = local.tags
}

resource "aws_iam_role_policy" "sfn" {
  count = var.enable ? 1 : 0
  role  = aws_iam_role.sfn[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_sfn_state_machine" "this" {
  count     = var.enable ? 1 : 0
  name      = "${local.name}-sfn"
  role_arn  = aws_iam_role.sfn[0].arn
  definition = local.sfn_definition
  tags      = local.tags
}

resource "aws_cloudformation_stack" "this" {
  count        = var.enable ? 1 : 0
  name         = "${local.name}-stack"
  template_body = <<-EOT
    AWSTemplateFormatVersion: '2010-09-09'
    Description: Community demo stack
    Resources:
      DemoTopic:
        Type: AWS::SNS::Topic
        Properties:
          TopicName: ${local.name}-cf-topic
  EOT
  tags = local.tags
}

resource "aws_iam_role" "config" {
  count = var.enable && var.component == "primary" ? 1 : 0
  name  = "${local.name}-config-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "config.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  tags = local.tags
}

resource "aws_iam_role_policy" "config" {
  count = var.enable && var.component == "primary" ? 1 : 0
  role  = aws_iam_role.config[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:GetObject", "s3:ListBucket"]
        Resource = [local.bucket_arn, "${local.bucket_arn}/*"]
      }
    ]
  })
}

resource "terraform_data" "config_recorder" {
  count = var.enable && var.component == "primary" ? 1 : 0

  input = {
    name         = "${local.name}-recorder"
    channel_name = "${local.name}-channel"
    bucket_name  = var.bucket_name
    role_arn     = aws_iam_role.config[0].arn
    region       = var.region
  }

  triggers_replace = {
    name         = "${local.name}-recorder"
    channel_name = "${local.name}-channel"
    bucket_name  = var.bucket_name
    role_arn     = aws_iam_role.config[0].arn
    region       = var.region
  }

  provisioner "local-exec" {
    command = <<-EOT
      existing_recorders="$(aws --endpoint-url "$LOCALSTACK_ENDPOINT" --region "${self.output.region}" configservice describe-configuration-recorders --query 'ConfigurationRecorders[].name' --output text 2>/dev/null || true)"
      for r in $existing_recorders; do
        aws --endpoint-url "$LOCALSTACK_ENDPOINT" --region "${self.output.region}" configservice delete-configuration-recorder --configuration-recorder-name "$r" >/dev/null 2>&1 || true
      done

      existing_channels="$(aws --endpoint-url "$LOCALSTACK_ENDPOINT" --region "${self.output.region}" configservice describe-delivery-channels --query 'DeliveryChannels[].name' --output text 2>/dev/null || true)"
      for c in $existing_channels; do
        aws --endpoint-url "$LOCALSTACK_ENDPOINT" --region "${self.output.region}" configservice delete-delivery-channel --delivery-channel-name "$c" >/dev/null 2>&1 || true
      done

      aws --endpoint-url "$LOCALSTACK_ENDPOINT" --region "${self.output.region}" configservice put-configuration-recorder \
        --configuration-recorder "name=${self.output.name},roleARN=${self.output.role_arn},recordingGroup={allSupported=true,includeGlobalResourceTypes=true}" >/dev/null 2>&1 || true

      aws --endpoint-url "$LOCALSTACK_ENDPOINT" --region "${self.output.region}" configservice put-delivery-channel \
        --delivery-channel "name=${self.output.channel_name},s3BucketName=${self.output.bucket_name}" >/dev/null 2>&1 || true

      aws --endpoint-url "$LOCALSTACK_ENDPOINT" --region "${self.output.region}" configservice start-configuration-recorder \
        --configuration-recorder-name "${self.output.name}" >/dev/null 2>&1 || true
    EOT
  }

  provisioner "local-exec" {
    when = destroy
    command = <<-EOT
      aws --endpoint-url "$LOCALSTACK_ENDPOINT" --region "${self.output.region}" configservice stop-configuration-recorder \
        --configuration-recorder-name "${self.output.name}" >/dev/null 2>&1 || true
      aws --endpoint-url "$LOCALSTACK_ENDPOINT" --region "${self.output.region}" configservice delete-configuration-recorder \
        --configuration-recorder-name "${self.output.name}" >/dev/null 2>&1 || true
      aws --endpoint-url "$LOCALSTACK_ENDPOINT" --region "${self.output.region}" configservice delete-delivery-channel \
        --delivery-channel-name "${self.output.channel_name}" >/dev/null 2>&1 || true
    EOT
  }
}

resource "aws_route53_zone" "this" {
  count = var.enable ? 1 : 0
  name  = "${local.name}.internal"
  vpc {
    vpc_id = var.vpc_id
  }
  tags = local.tags
}

resource "aws_route53_record" "this" {
  count   = var.enable ? 1 : 0
  zone_id = aws_route53_zone.this[0].zone_id
  name    = "app.${local.name}.internal"
  type    = "CNAME"
  ttl     = 30
  records = ["example.local"]
}

resource "aws_security_group" "resolver" {
  count       = var.enable ? 1 : 0
  name        = "${local.name}-resolver-sg"
  description = "Resolver endpoint security group"
  vpc_id      = var.vpc_id

  ingress {
    protocol    = "udp"
    from_port   = 53
    to_port     = 53
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 53
    to_port     = 53
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

resource "aws_route53_resolver_endpoint" "this" {
  count     = var.enable ? 1 : 0
  name      = "${local.name}-resolver"
  direction = "OUTBOUND"
  security_group_ids = [aws_security_group.resolver[0].id]

  ip_address {
    subnet_id = local.subnet_ids[0]
  }

  ip_address {
    subnet_id = local.subnet_ids[1]
  }

  tags = local.tags
}

resource "aws_opensearch_domain" "this" {
  count         = var.enable && var.enable_opensearch ? 1 : 0
  domain_name   = local.opensearch_domain_name
  engine_version = "OpenSearch_2.11"

  cluster_config {
    instance_type  = "t3.small.search"
    instance_count = 1
  }

  ebs_options {
    ebs_enabled = true
    volume_size = 10
    volume_type = "gp2"
  }

  tags = local.tags
}

resource "terraform_data" "redshift_subnet_group" {
  count = var.enable ? 1 : 0

  input = {
    name        = "${local.name}-redshift-subnets"
    subnet_ids  = local.subnet_ids
    description = "Subnet group for ${local.name} Redshift"
    region      = var.region
  }

  triggers_replace = {
    name        = "${local.name}-redshift-subnets"
    subnet_ids  = join(",", local.subnet_ids)
    description = "Subnet group for ${local.name} Redshift"
    region      = var.region
  }

  provisioner "local-exec" {
    command = <<-EOT
      aws --endpoint-url "$LOCALSTACK_ENDPOINT" --region "${self.output.region}" redshift create-cluster-subnet-group \
        --cluster-subnet-group-name "${self.output.name}" \
        --description "${self.output.description}" \
        --subnet-ids ${join(" ", local.subnet_ids)} >/dev/null 2>&1 || true
    EOT
  }

  provisioner "local-exec" {
    when = destroy
    command = <<-EOT
      aws --endpoint-url "$LOCALSTACK_ENDPOINT" --region "${self.output.region}" redshift delete-cluster-subnet-group \
        --cluster-subnet-group-name "${self.output.name}" >/dev/null 2>&1 || true
    EOT
  }
}

resource "terraform_data" "redshift_cluster" {
  count = var.enable ? 1 : 0

  input = {
    name        = "${local.name}-redshift"
    region      = var.region
    subnet_group = terraform_data.redshift_subnet_group[0].output.name
    component   = var.component
  }

  triggers_replace = {
    name        = "${local.name}-redshift"
    region      = var.region
    subnet_group = terraform_data.redshift_subnet_group[0].output.name
    component   = var.component
  }

  provisioner "local-exec" {
    command = <<-EOT
      if ! aws --endpoint-url "$LOCALSTACK_ENDPOINT" --region "${self.output.region}" redshift describe-clusters --cluster-identifier "${self.output.name}" >/dev/null 2>&1; then
        aws --endpoint-url "$LOCALSTACK_ENDPOINT" --region "${self.output.region}" redshift create-cluster \
          --cluster-identifier "${self.output.name}" \
          --cluster-type single-node \
          --node-type dc2.large \
          --db-name dev \
          --master-username master \
          --master-user-password ChangeMe123! \
          --cluster-subnet-group-name "${self.output.subnet_group}" \
          --tags Key=component,Value="${self.output.component}" Key=region,Value="${self.output.region}" >/dev/null 2>&1 || true
      fi
    EOT
  }

  provisioner "local-exec" {
    when = destroy
    command = <<-EOT
      aws --endpoint-url "$LOCALSTACK_ENDPOINT" --region "${self.output.region}" redshift delete-cluster \
        --cluster-identifier "${self.output.name}" \
        --skip-final-cluster-snapshot >/dev/null 2>&1 || true
    EOT
  }
}
