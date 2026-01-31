terraform {
  required_version = ">= 1.4.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  access_key                  = var.aws_access_key_id
  secret_key                  = var.aws_secret_access_key
  region                      = var.primary_region
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    s3            = var.localstack_endpoint
    iam           = var.localstack_endpoint
    sts           = var.localstack_endpoint
    ec2           = var.localstack_endpoint
    lambda        = var.localstack_endpoint
    dynamodb      = var.localstack_endpoint
    dynamodbstreams = var.localstack_endpoint
    es            = var.localstack_endpoint
    opensearch    = var.localstack_endpoint
    redshift      = var.localstack_endpoint
    sqs           = var.localstack_endpoint
    sns           = var.localstack_endpoint
    events        = var.localstack_endpoint
    scheduler     = var.localstack_endpoint
    ses           = var.localstack_endpoint
    stepfunctions = var.localstack_endpoint
    apigateway    = var.localstack_endpoint
    cloudformation = var.localstack_endpoint
    cloudwatch    = var.localstack_endpoint
    logs          = var.localstack_endpoint
    ssm           = var.localstack_endpoint
    configservice = var.localstack_endpoint
    route53       = var.localstack_endpoint
    route53resolver = var.localstack_endpoint
    autoscaling   = var.localstack_endpoint
    elb           = var.localstack_endpoint
    elbv2         = var.localstack_endpoint
    acm           = var.localstack_endpoint
    rds           = var.localstack_endpoint
  }
}

provider "aws" {
  alias                       = "secondary"
  access_key                  = var.aws_access_key_id
  secret_key                  = var.aws_secret_access_key
  region                      = var.secondary_region
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    s3            = var.localstack_endpoint
    iam           = var.localstack_endpoint
    sts           = var.localstack_endpoint
    ec2           = var.localstack_endpoint
    lambda        = var.localstack_endpoint
    dynamodb      = var.localstack_endpoint
    dynamodbstreams = var.localstack_endpoint
    es            = var.localstack_endpoint
    opensearch    = var.localstack_endpoint
    redshift      = var.localstack_endpoint
    sqs           = var.localstack_endpoint
    sns           = var.localstack_endpoint
    events        = var.localstack_endpoint
    scheduler     = var.localstack_endpoint
    ses           = var.localstack_endpoint
    stepfunctions = var.localstack_endpoint
    apigateway    = var.localstack_endpoint
    cloudformation = var.localstack_endpoint
    cloudwatch    = var.localstack_endpoint
    logs          = var.localstack_endpoint
    ssm           = var.localstack_endpoint
    configservice = var.localstack_endpoint
    route53       = var.localstack_endpoint
    route53resolver = var.localstack_endpoint
    autoscaling   = var.localstack_endpoint
    elb           = var.localstack_endpoint
    elbv2         = var.localstack_endpoint
    acm           = var.localstack_endpoint
    rds           = var.localstack_endpoint
  }
}

locals {
  base_tags = {
    project = var.name_prefix
    env     = var.environment
  }
  public_subnet_newbits  = coalesce(var.public_subnet_newbits, var.subnet_newbits)
  private_subnet_newbits = coalesce(var.private_subnet_newbits, var.subnet_newbits)
  public_subnet_count    = coalesce(var.public_subnet_count, var.az_count)
  private_subnet_count   = coalesce(var.private_subnet_count, var.az_count)
}

module "primary" {
  source              = "./modules/ha_region"
  providers           = { aws = aws }
  name_prefix         = var.name_prefix
  component           = "primary"
  environment         = var.environment
  region              = var.primary_region
  vpc_cidr            = var.primary_vpc_cidr
  public_subnet_newbits  = local.public_subnet_newbits
  private_subnet_newbits = local.private_subnet_newbits
  public_subnet_count    = local.public_subnet_count
  private_subnet_count   = local.private_subnet_count
  enable_private_subnets = var.enable_private_subnets
  simulate_unsupported = var.simulate_unsupported
  localstack_pro      = var.localstack_pro
  az_count            = var.az_count
  app_instance_type   = var.app_instance_type
  db_instance_class   = var.db_instance_class
  db_engine           = var.db_engine
  db_engine_version   = var.db_engine_version
  db_username         = var.db_username
  db_password         = var.db_password
  alb_count           = var.alb_count
  asg_min_size        = var.asg_min_size
  asg_max_size        = var.asg_max_size
  asg_desired_capacity = var.asg_desired_capacity
  tags                = local.base_tags
}

module "secondary" {
  source              = "./modules/ha_region"
  providers           = { aws = aws.secondary }
  name_prefix         = var.name_prefix
  component           = "secondary"
  environment         = var.environment
  region              = var.secondary_region
  vpc_cidr            = var.secondary_vpc_cidr
  public_subnet_newbits  = local.public_subnet_newbits
  private_subnet_newbits = local.private_subnet_newbits
  public_subnet_count    = local.public_subnet_count
  private_subnet_count   = local.private_subnet_count
  enable_private_subnets = var.enable_private_subnets
  simulate_unsupported = var.simulate_unsupported
  localstack_pro      = var.localstack_pro
  az_count            = var.az_count
  app_instance_type   = var.app_instance_type
  db_instance_class   = var.db_instance_class
  db_engine           = var.db_engine
  db_engine_version   = var.db_engine_version
  db_username         = var.db_username
  db_password         = var.db_password
  alb_count           = var.alb_count
  asg_min_size        = var.asg_min_size
  asg_max_size        = var.asg_max_size
  asg_desired_capacity = var.asg_desired_capacity
  tags                = local.base_tags
}

module "community_primary" {
  source             = "./modules/community_services"
  providers          = { aws = aws }
  enable             = var.enable_community_services
  enable_lambda      = var.enable_lambda
  enable_opensearch  = var.enable_opensearch
  name_prefix        = var.name_prefix
  component          = "primary"
  region             = var.primary_region
  vpc_id             = module.primary.vpc_id
  public_subnet_ids  = module.primary.public_subnet_ids
  private_subnet_ids = module.primary.private_subnet_ids
  bucket_name        = module.primary.bucket_name
  tags               = local.base_tags
}

module "community_secondary" {
  source             = "./modules/community_services"
  providers          = { aws = aws.secondary }
  enable             = var.enable_community_services
  enable_lambda      = var.enable_lambda
  enable_opensearch  = var.enable_opensearch
  name_prefix        = var.name_prefix
  component          = "secondary"
  region             = var.secondary_region
  vpc_id             = module.secondary.vpc_id
  public_subnet_ids  = module.secondary.public_subnet_ids
  private_subnet_ids = module.secondary.private_subnet_ids
  bucket_name        = module.secondary.bucket_name
  tags               = local.base_tags
}
