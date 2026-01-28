.PHONY: help tf-init tf-apply ansible-run aws-sts aws-s3-list pulumi-python-up pulumi-python-destroy pulumi-python-full-up pulumi-python-full-destroy health smoke

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

tf-init: ## terraform init (offline cache)
	@tf-init

tf-apply: ## terraform apply
	@tf-apply

ansible-run: ## run Ansible playbook
	@ansible-run

aws-sts: ## aws sts get-caller-identity
	@aws sts get-caller-identity

aws-s3-list: ## aws s3api list-buckets
	@aws s3api list-buckets

PULUMI_STACK ?= dev
PULUMI_PY_DIR := /home/sandbox/workspace/pulumi/python

pulumi-python-init:
	@pulumi-python -C $(PULUMI_PY_DIR) stack select $(PULUMI_STACK) || pulumi-python -C $(PULUMI_PY_DIR) stack init $(PULUMI_STACK)

pulumi-python-up: pulumi-python-init ## pulumi up (python)
	@pulumi-python -C $(PULUMI_PY_DIR) up -y --stack $(PULUMI_STACK)

pulumi-python-destroy: pulumi-python-init ## pulumi destroy (python)
	@pulumi-python -C $(PULUMI_PY_DIR) destroy -y --stack $(PULUMI_STACK)

pulumi-python-full-up: ## pulumi up (python, full stack)
	@pulumi-python -C $(PULUMI_PY_DIR) stack select full || pulumi-python -C $(PULUMI_PY_DIR) stack init full
	@pulumi-python -C $(PULUMI_PY_DIR) config set simulateUnsupported false --stack full
	@pulumi-python -C $(PULUMI_PY_DIR) up -y --stack full

pulumi-python-full-destroy: ## pulumi destroy (python, full stack)
	@pulumi-python -C $(PULUMI_PY_DIR) stack select full || pulumi-python -C $(PULUMI_PY_DIR) stack init full
	@pulumi-python -C $(PULUMI_PY_DIR) destroy -y --stack full

health: ## sandbox healthcheck (awscli against LocalStack)
	@if [ -z "$${LOCALSTACK_ENDPOINT:-}" ]; then echo "LOCALSTACK_ENDPOINT not set"; exit 1; fi
	@aws --endpoint-url "$$LOCALSTACK_ENDPOINT" sts get-caller-identity >/dev/null
	@aws --endpoint-url "$$LOCALSTACK_ENDPOINT" s3api list-buckets >/dev/null
	@echo "sandbox health: ok"

smoke: ## sandbox awscli smoke test
	@if [ -z "$${LOCALSTACK_ENDPOINT:-}" ]; then echo "LOCALSTACK_ENDPOINT not set"; exit 1; fi
	@aws --endpoint-url "$$LOCALSTACK_ENDPOINT" sts get-caller-identity >/dev/null
	@aws --endpoint-url "$$LOCALSTACK_ENDPOINT" s3api list-buckets >/dev/null
	@echo "sandbox awscli: ok"
