.PHONY: help toolchain tf-init tf-apply tf-interactive verify cleanup wipe ansible-run ansible-plan ansible-destroy aws-help aws-overview aws-sts aws-s3-list pulumi-python-up pulumi-python-destroy pulumi-python-full-up pulumi-python-full-destroy destroy-all health smoke

CONFIRM ?= 1

define confirm
	@if [ "$(CONFIRM)" = "1" ]; then \
	  printf "About to run: %s\n%s\n\nPress Enter to continue..." "$(1)" "$(2)"; \
	  read -r _; \
	  echo ""; \
	fi
endef

help: ## show available targets
	@printf "Targets:\n"
	@while IFS= read -r line; do \
		case "$$line" in \
			[a-zA-Z0-9_-]*:*"##"*) \
				target=$${line%%:*}; \
				desc=$${line##*## }; \
				printf "  %-22s %s\n" "$$target" "$$desc"; \
				;; \
		esac; \
	done < $(firstword $(MAKEFILE_LIST))

toolchain: ## show the recommended Terraform -> Ansible -> AWS CLI flow
	@echo "Recommended flow:"; \
	echo "  1) make tf-interactive  - Terraform builds the infrastructure."; \
	echo "  2) make ansible-run     - Ansible configures what Terraform created."; \
	echo "  3) make aws-overview    - AWS CLI inspects everything in LocalStack."; \
	echo ""; \
	echo "Why this order?"; \
	echo "  Terraform defines and creates the infrastructure."; \
	echo "  Ansible configures and customizes those resources."; \
	echo "  AWS CLI verifies the final state.";

aws-help: ## show useful AWS CLI commands
	@if [ -z "$${LOCALSTACK_ENDPOINT:-}" ]; then echo "LOCALSTACK_ENDPOINT not set"; exit 1; fi
	@echo "Useful AWS CLI commands (LocalStack):"; \
	echo "LOCALSTACK_ENDPOINT is required and must already be set in your environment."; \
	echo ""; \
	echo "EC2 instances (primary region):"; \
	echo "  aws --endpoint-url \"$$LOCALSTACK_ENDPOINT\" --region us-east-1 ec2 describe-instances \\"; \
	echo "    --query 'Reservations[].Instances[].{Id:InstanceId,State:State.Name,Type:InstanceType}' --output table"; \
	echo ""; \
	echo "EC2 instances (secondary region):"; \
	echo "  aws --endpoint-url \"$$LOCALSTACK_ENDPOINT\" --region us-west-2 ec2 describe-instances \\"; \
	echo "    --query 'Reservations[].Instances[].{Id:InstanceId,State:State.Name,Type:InstanceType}' --output table"; \
	echo ""; \
	echo "S3 buckets:"; \
	echo "  aws --endpoint-url \"$$LOCALSTACK_ENDPOINT\" s3api list-buckets --output table"; \
	echo ""; \
	echo "DynamoDB tables:"; \
	echo "  aws --endpoint-url \"$$LOCALSTACK_ENDPOINT\" dynamodb list-tables --output table"; \
	echo ""; \
	echo "DynamoDB streams:"; \
	echo "  aws --endpoint-url \"$$LOCALSTACK_ENDPOINT\" dynamodbstreams list-streams --output table"; \
	echo ""; \
	echo "Lambda functions:"; \
	echo "  aws --endpoint-url \"$$LOCALSTACK_ENDPOINT\" lambda list-functions --output table"; \
	echo ""; \
	echo "SQS queues:"; \
	echo "  aws --endpoint-url \"$$LOCALSTACK_ENDPOINT\" sqs list-queues --output table"; \
	echo ""; \
	echo "SNS topics:"; \
	echo "  aws --endpoint-url \"$$LOCALSTACK_ENDPOINT\" sns list-topics --output table"; \
	echo ""; \
	echo "EventBridge buses:"; \
	echo "  aws --endpoint-url \"$$LOCALSTACK_ENDPOINT\" events list-event-buses --output table"; \
	echo ""; \
	echo "EventBridge Scheduler schedules:"; \
	echo "  aws --endpoint-url \"$$LOCALSTACK_ENDPOINT\" scheduler list-schedules --output table"; \
	echo ""; \
	echo "SES identities:"; \
	echo "  aws --endpoint-url \"$$LOCALSTACK_ENDPOINT\" ses list-identities --output table"; \
	echo ""; \
	echo "Step Functions state machines:"; \
	echo "  aws --endpoint-url \"$$LOCALSTACK_ENDPOINT\" stepfunctions list-state-machines --output table"; \
	echo ""; \
	echo "API Gateway REST APIs:"; \
	echo "  aws --endpoint-url \"$$LOCALSTACK_ENDPOINT\" apigateway get-rest-apis --output table"; \
	echo ""; \
	echo "CloudFormation stacks:"; \
	echo "  aws --endpoint-url \"$$LOCALSTACK_ENDPOINT\" cloudformation list-stacks \\"; \
	echo "    --query 'StackSummaries[].{Name:StackName,Status:StackStatus}' --output table"; \
	echo ""; \
	echo "CloudWatch metrics:"; \
	echo "  aws --endpoint-url \"$$LOCALSTACK_ENDPOINT\" cloudwatch list-metrics --output table"; \
	echo ""; \
	echo "CloudWatch logs:"; \
	echo "  aws --endpoint-url \"$$LOCALSTACK_ENDPOINT\" logs describe-log-groups --output table"; \
	echo ""; \
	echo "SSM parameters:"; \
	echo "  aws --endpoint-url \"$$LOCALSTACK_ENDPOINT\" ssm describe-parameters --output table"; \
	echo ""; \
	echo "Config recorders:"; \
	echo "  aws --endpoint-url \"$$LOCALSTACK_ENDPOINT\" configservice describe-configuration-recorders --output table"; \
	echo ""; \
	echo "IAM roles:"; \
	echo "  aws --endpoint-url \"$$LOCALSTACK_ENDPOINT\" iam list-roles --output table"; \
	echo ""; \
	echo "STS identity:"; \
	echo "  aws --endpoint-url \"$$LOCALSTACK_ENDPOINT\" sts get-caller-identity --output table"; \
	echo ""; \
	echo "OpenSearch/Elasticsearch domains:"; \
	echo "  aws --endpoint-url \"$$LOCALSTACK_ENDPOINT\" es list-domain-names --output table"; \
	echo ""; \
	echo "Redshift clusters:"; \
	echo "  aws --endpoint-url \"$$LOCALSTACK_ENDPOINT\" redshift describe-clusters --output table"; \
	echo ""; \
	echo "VPCs:"; \
	echo "  aws --endpoint-url \"$$LOCALSTACK_ENDPOINT\" ec2 describe-vpcs \\"; \
	echo "    --query 'Vpcs[].{VpcId:VpcId,Cidr:CidrBlock,Name:Tags[?Key==\\`Name\\`]|[0].Value}' --output table"; \
	echo ""; \
	echo "Subnets:"; \
	echo "  aws --endpoint-url \"$$LOCALSTACK_ENDPOINT\" ec2 describe-subnets \\"; \
	echo "    --query 'Subnets[].{SubnetId:SubnetId,Cidr:CidrBlock,Az:AvailabilityZone,Name:Tags[?Key==\\`Name\\`]|[0].Value}' --output table"; \
	echo ""; \
	echo "Security groups:"; \
	echo "  aws --endpoint-url \"$$LOCALSTACK_ENDPOINT\" ec2 describe-security-groups \\"; \
	echo "    --query 'SecurityGroups[].{GroupId:GroupId,Name:GroupName,VpcId:VpcId}' --output table"; \
	echo ""; \
	echo "Route 53 hosted zones:"; \
	echo "  aws --endpoint-url \"$$LOCALSTACK_ENDPOINT\" route53 list-hosted-zones \\"; \
	echo "    --query 'HostedZones[].{Id:Id,Name:Name,Private:Config.PrivateZone}' --output table"; \
	echo ""; \
	echo "Route 53 record sets (replace ZONE_ID):"; \
	echo "  aws --endpoint-url \"$$LOCALSTACK_ENDPOINT\" route53 list-resource-record-sets --hosted-zone-id ZONE_ID \\"; \
	echo "    --query 'ResourceRecordSets[].{Name:Name,Type:Type,TTL:TTL}' --output table"; \
	echo ""; \
	echo "Route 53 resolver endpoints:"; \
	echo "  aws --endpoint-url \"$$LOCALSTACK_ENDPOINT\" route53resolver list-resolver-endpoints --output table"; \
	echo ""; \
	echo "Tip: JMESPath queries use single quotes; remove any leading pipes or extra symbols."

aws-overview: ## run a full AWS resource overview
	@if [ -z "$${LOCALSTACK_ENDPOINT:-}" ]; then echo "LOCALSTACK_ENDPOINT not set"; exit 1; fi
	@echo "AWS overview (LocalStack)"; \
	echo ""; \
	echo "==> EC2 instances (us-east-1)"; \
	aws --endpoint-url "$$LOCALSTACK_ENDPOINT" --region us-east-1 ec2 describe-instances \
	  --query 'Reservations[].Instances[].{Id:InstanceId,State:State.Name,Type:InstanceType,Name:Tags[?Key==`Name`]|[0].Value,Simulated:Tags[?Key==`simulated`]|[0].Value,Component:Tags[?Key==`app_component`]|[0].Value}' --output table || true; \
	echo ""; \
	echo "==> EC2 instances (us-west-2)"; \
	aws --endpoint-url "$$LOCALSTACK_ENDPOINT" --region us-west-2 ec2 describe-instances \
	  --query 'Reservations[].Instances[].{Id:InstanceId,State:State.Name,Type:InstanceType,Name:Tags[?Key==`Name`]|[0].Value,Simulated:Tags[?Key==`simulated`]|[0].Value,Component:Tags[?Key==`app_component`]|[0].Value}' --output table || true; \
	echo ""; \
	echo "==> S3 buckets"; \
	aws --endpoint-url "$$LOCALSTACK_ENDPOINT" s3api list-buckets --output table || true; \
	echo ""; \
	echo "==> DynamoDB tables"; \
	aws --endpoint-url "$$LOCALSTACK_ENDPOINT" dynamodb list-tables --output table || true; \
	echo ""; \
	echo "==> DynamoDB streams"; \
	aws --endpoint-url "$$LOCALSTACK_ENDPOINT" dynamodbstreams list-streams --output table || true; \
	echo ""; \
	echo "==> Lambda functions"; \
	aws --endpoint-url "$$LOCALSTACK_ENDPOINT" lambda list-functions --output table || true; \
	echo ""; \
	echo "==> SQS queues"; \
	aws --endpoint-url "$$LOCALSTACK_ENDPOINT" sqs list-queues --output table || true; \
	echo ""; \
	echo "==> SNS topics"; \
	aws --endpoint-url "$$LOCALSTACK_ENDPOINT" sns list-topics --output table || true; \
	echo ""; \
	echo "==> EventBridge buses"; \
	aws --endpoint-url "$$LOCALSTACK_ENDPOINT" events list-event-buses --output table || true; \
	echo ""; \
	echo "==> EventBridge Scheduler schedules"; \
	aws --endpoint-url "$$LOCALSTACK_ENDPOINT" scheduler list-schedules --output table || true; \
	echo ""; \
	echo "==> SES identities"; \
	aws --endpoint-url "$$LOCALSTACK_ENDPOINT" ses list-identities --output table || true; \
	echo ""; \
	echo "==> Step Functions state machines"; \
	aws --endpoint-url "$$LOCALSTACK_ENDPOINT" stepfunctions list-state-machines --output table || true; \
	echo ""; \
	echo "==> API Gateway REST APIs"; \
	aws --endpoint-url "$$LOCALSTACK_ENDPOINT" apigateway get-rest-apis --output table || true; \
	echo ""; \
	echo "==> CloudFormation stacks"; \
	aws --endpoint-url "$$LOCALSTACK_ENDPOINT" cloudformation list-stacks \
	  --query 'StackSummaries[].{Name:StackName,Status:StackStatus}' --output table || true; \
	echo ""; \
	echo "==> CloudWatch metrics"; \
	aws --endpoint-url "$$LOCALSTACK_ENDPOINT" cloudwatch list-metrics --output table || true; \
	echo ""; \
	echo "==> CloudWatch logs"; \
	aws --endpoint-url "$$LOCALSTACK_ENDPOINT" logs describe-log-groups --output table || true; \
	echo ""; \
	echo "==> SSM parameters"; \
	aws --endpoint-url "$$LOCALSTACK_ENDPOINT" ssm describe-parameters --output table || true; \
	echo ""; \
	echo "==> Config recorders"; \
	aws --endpoint-url "$$LOCALSTACK_ENDPOINT" configservice describe-configuration-recorders --output table || true; \
	echo ""; \
	echo "==> IAM roles"; \
	aws --endpoint-url "$$LOCALSTACK_ENDPOINT" iam list-roles --output table || true; \
	echo ""; \
	echo "==> STS identity"; \
	aws --endpoint-url "$$LOCALSTACK_ENDPOINT" sts get-caller-identity --output table || true; \
	echo ""; \
	echo "==> OpenSearch/Elasticsearch domains"; \
	aws --endpoint-url "$$LOCALSTACK_ENDPOINT" es list-domain-names --output table || true; \
	echo ""; \
	echo "==> Redshift clusters"; \
	aws --endpoint-url "$$LOCALSTACK_ENDPOINT" redshift describe-clusters --output table || true; \
	echo ""; \
	echo "==> VPCs"; \
	aws --endpoint-url "$$LOCALSTACK_ENDPOINT" ec2 describe-vpcs \
	  --query 'Vpcs[].{VpcId:VpcId,Cidr:CidrBlock,Name:Tags[?Key==`Name`]|[0].Value}' --output table || true; \
	echo ""; \
	echo "==> Subnets"; \
	aws --endpoint-url "$$LOCALSTACK_ENDPOINT" ec2 describe-subnets \
	  --query 'Subnets[].{SubnetId:SubnetId,Cidr:CidrBlock,Az:AvailabilityZone,Name:Tags[?Key==`Name`]|[0].Value}' --output table || true; \
	echo ""; \
	echo "==> Security groups"; \
	aws --endpoint-url "$$LOCALSTACK_ENDPOINT" ec2 describe-security-groups \
	  --query 'SecurityGroups[].{GroupId:GroupId,Name:GroupName,VpcId:VpcId}' --output table || true; \
	echo ""; \
	echo "==> Route 53 hosted zones"; \
	aws --endpoint-url "$$LOCALSTACK_ENDPOINT" route53 list-hosted-zones \
	  --query 'HostedZones[].{Id:Id,Name:Name,Private:Config.PrivateZone}' --output table || true; \
	echo ""; \
	echo "==> Route 53 record sets"; \
	zones=$$(aws --endpoint-url "$$LOCALSTACK_ENDPOINT" route53 list-hosted-zones --query 'HostedZones[].Id' --output text 2>/dev/null); \
	if [ -n "$$zones" ]; then \
	  for z in $$zones; do \
	    echo "-- Zone $$z"; \
	    aws --endpoint-url "$$LOCALSTACK_ENDPOINT" route53 list-resource-record-sets --hosted-zone-id "$$z" \
	      --query 'ResourceRecordSets[].{Name:Name,Type:Type,TTL:TTL}' --output table || true; \
	  done; \
	else \
	  echo "No hosted zones found."; \
	fi
	@echo ""; \
	echo "==> Route 53 resolver endpoints"; \
	aws --endpoint-url "$$LOCALSTACK_ENDPOINT" route53resolver list-resolver-endpoints --output table || true

tf-init: ## terraform init (offline cache)
	$(call confirm,tf-init,Initialize Terraform using the offline provider cache.)
	@tf-init

tf-apply: ## terraform apply
	$(call confirm,tf-apply,Apply Terraform for both regions against LocalStack.)
	@tf-apply

tf-interactive: ## terraform interactive wizard
	$(call confirm,tf-interactive,Prompt for Terraform inputs and apply against LocalStack.)
	@tf-interactive

verify: ## show terraform outputs and key LocalStack resources
	$(call confirm,verify,Show Terraform outputs and key AWS resources in LocalStack.)
	@endpoint=$${LOCALSTACK_ENDPOINT:-http://localstack:4566}; \
	echo "Using LocalStack endpoint: $$endpoint"; \
	echo ""; \
	echo "Terraform state:"; \
	terraform state list || true; \
	echo ""; \
	echo "Terraform outputs:"; \
	terraform output || true; \
	echo ""; \
	echo "S3 buckets:"; \
	aws --endpoint-url "$$endpoint" s3api list-buckets || true; \
	echo ""; \
	echo "VPCs:"; \
	aws --endpoint-url "$$endpoint" ec2 describe-vpcs --query 'Vpcs[].{VpcId:VpcId,Cidr:CidrBlock,Name:Tags[?Key==`Name`]|[0].Value}' --output table || true; \
	echo ""; \
	echo "Subnets:"; \
	aws --endpoint-url "$$endpoint" ec2 describe-subnets --query 'Subnets[].{SubnetId:SubnetId,Cidr:CidrBlock,Az:AvailabilityZone,Name:Tags[?Key==`Name`]|[0].Value}' --output table || true; \
	echo ""; \
	echo "Auto Scaling Groups:"; \
	if ! aws --endpoint-url "$$endpoint" autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[].{Name:AutoScalingGroupName,Min:MinSize,Max:MaxSize,Desired:DesiredCapacity}' --output table 2>/dev/null; then \
	  echo "Autoscaling not available in this LocalStack plan."; \
	fi; \
	echo ""; \
	echo "Load Balancers:"; \
	if ! aws --endpoint-url "$$endpoint" elbv2 describe-load-balancers --query 'LoadBalancers[].{Name:LoadBalancerName,Type:Type,Scheme:Scheme,DNS:DNSName}' --output table 2>/dev/null; then \
	  echo "ELBv2 not available in this LocalStack plan."; \
	fi; \
	echo ""; \
	echo "RDS instances:"; \
	if ! aws --endpoint-url "$$endpoint" rds describe-db-instances --query 'DBInstances[].{Id:DBInstanceIdentifier,Class:DBInstanceClass,Engine:Engine,Status:DBInstanceStatus,Endpoint:Endpoint.Address}' --output table 2>/dev/null; then \
	  echo "RDS not available in this LocalStack plan."; \
	fi; \
	echo ""; \
	echo "RDS clusters:"; \
	if ! aws --endpoint-url "$$endpoint" rds describe-db-clusters --query 'DBClusters[].{Id:DBClusterIdentifier,Engine:Engine,Status:Status,Endpoint:Endpoint}' --output table 2>/dev/null; then \
	  echo "RDS not available in this LocalStack plan."; \
	fi

cleanup: ## remove all LocalStack resources (best effort)
	$(call confirm,cleanup,Remove all LocalStack resources created in this sandbox (best effort).)
	@localstack-cleanup

wipe: ## full reset (LocalStack + Terraform state + Ansible artifacts)
	@echo "Wiping LocalStack resources and workspace state..."; \
	localstack-cleanup >/dev/null 2>&1 || true; \
	rm -rf /workspace/terraform/.terraform /workspace/terraform/terraform.tfstate /workspace/terraform/terraform.tfstate.backup; \
	rm -f /workspace/terraform/.terraform.lock.hcl /workspace/terraform/interactive.auto.tfvars /workspace/terraform/interactive.apply.log /workspace/terraform/interactive.destroy.log; \
	rm -rf /workspace/terraform/modules/ha_region/.mock-ec2; \
	rm -rf /workspace/.ansible/tmp

ansible-run: ## run Ansible playbook
	$(call confirm,ansible-run,Run the Ansible playbook against LocalStack.)
	@echo "Step 2/3: Ansible configures the resources Terraform created."; \
	ansible-run

ansible-plan: ## Ansible dry run (check mode)
	$(call confirm,ansible-plan,Preview the Ansible playbook changes against LocalStack.)
	@ansible-plan

ansible-destroy: ## destroy Ansible-created resources
	$(call confirm,ansible-destroy,Remove resources created by the Ansible playbook.)
	@ansible-destroy

aws-sts: ## aws sts get-caller-identity
	$(call confirm,aws-sts,Query the LocalStack STS endpoint.)
	@aws sts get-caller-identity

aws-s3-list: ## aws s3api list-buckets
	$(call confirm,aws-s3-list,List all S3 buckets in LocalStack.)
	@aws s3api list-buckets

PULUMI_STACK ?= dev
PULUMI_PY_DIR := /home/sandbox/workspace/pulumi/python

pulumi-python-init:
	@pulumi-python -C $(PULUMI_PY_DIR) stack select $(PULUMI_STACK) || pulumi-python -C $(PULUMI_PY_DIR) stack init $(PULUMI_STACK)

pulumi-python-up: ## pulumi up (python)
	$(call confirm,pulumi-python-up,Preview and apply the Pulumi Python stack in LocalStack.)
	@pulumi-python -C $(PULUMI_PY_DIR) stack select $(PULUMI_STACK) || pulumi-python -C $(PULUMI_PY_DIR) stack init $(PULUMI_STACK)
	@pulumi-python -C $(PULUMI_PY_DIR) up -y --stack $(PULUMI_STACK)

pulumi-python-destroy: ## pulumi destroy (python)
	$(call confirm,pulumi-python-destroy,Destroy the Pulumi Python stack in LocalStack.)
	@pulumi-python -C $(PULUMI_PY_DIR) stack select $(PULUMI_STACK) || pulumi-python -C $(PULUMI_PY_DIR) stack init $(PULUMI_STACK)
	@pulumi-python -C $(PULUMI_PY_DIR) destroy -y --stack $(PULUMI_STACK)

pulumi-python-full-up: ## pulumi up (python, full stack)
	$(call confirm,pulumi-python-full-up,Preview and apply the full Pulumi Python stack in LocalStack.)
	@pulumi-python -C $(PULUMI_PY_DIR) stack select full || pulumi-python -C $(PULUMI_PY_DIR) stack init full
	@pulumi-python -C $(PULUMI_PY_DIR) config set simulateUnsupported false --stack full
	@pulumi-python -C $(PULUMI_PY_DIR) up -y --stack full

pulumi-python-full-destroy: ## pulumi destroy (python, full stack)
	$(call confirm,pulumi-python-full-destroy,Destroy the full Pulumi Python stack in LocalStack.)
	@pulumi-python -C $(PULUMI_PY_DIR) stack select full || pulumi-python -C $(PULUMI_PY_DIR) stack init full
	@pulumi-python -C $(PULUMI_PY_DIR) destroy -y --stack full

destroy-all: ## destroy Pulumi stacks and wipe all S3 buckets
	$(call confirm,destroy-all,Destroy all Pulumi stacks and remove every S3 bucket in LocalStack.)
	@if [ -z "$${LOCALSTACK_ENDPOINT:-}" ]; then echo "LOCALSTACK_ENDPOINT not set"; exit 1; fi
	@echo "Destroying Pulumi stacks..."
	@$(MAKE) pulumi-python-destroy || echo "pulumi-python-destroy failed (continuing)"
	@$(MAKE) pulumi-python-full-destroy || echo "pulumi-python-full-destroy failed (continuing)"
	@echo "Wiping S3 buckets..."
	@buckets=$$(aws --endpoint-url "$$LOCALSTACK_ENDPOINT" s3api list-buckets --query 'Buckets[].Name' --output text); \
	if [ -n "$$buckets" ]; then \
	  for b in $$buckets; do \
	    aws --endpoint-url "$$LOCALSTACK_ENDPOINT" s3 rm "s3://$$b" --recursive >/dev/null 2>&1 || true; \
	    aws --endpoint-url "$$LOCALSTACK_ENDPOINT" s3api delete-bucket --bucket "$$b" >/dev/null 2>&1 || true; \
	  done; \
	fi; \
	echo "destroy-all: done"

health: ## iac-sandbox healthcheck (awscli against LocalStack)
	$(call confirm,health,Run a basic AWS CLI health check against LocalStack.)
	@if [ -z "$${LOCALSTACK_ENDPOINT:-}" ]; then echo "LOCALSTACK_ENDPOINT not set"; exit 1; fi
	@aws --endpoint-url "$$LOCALSTACK_ENDPOINT" sts get-caller-identity >/dev/null
	@aws --endpoint-url "$$LOCALSTACK_ENDPOINT" s3api list-buckets >/dev/null
	@echo "iac-sandbox health: ok"

smoke: ## iac-sandbox awscli smoke test
	$(call confirm,smoke,Run a simple AWS CLI smoke test against LocalStack.)
	@if [ -z "$${LOCALSTACK_ENDPOINT:-}" ]; then echo "LOCALSTACK_ENDPOINT not set"; exit 1; fi
	@aws --endpoint-url "$$LOCALSTACK_ENDPOINT" sts get-caller-identity >/dev/null
	@aws --endpoint-url "$$LOCALSTACK_ENDPOINT" s3api list-buckets >/dev/null
	@echo "iac-sandbox awscli: ok"
