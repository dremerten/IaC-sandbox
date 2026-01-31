variable "aws_access_key_id" {
  type        = string
  description = "Access key for LocalStack"
  default     = "test"
}

variable "aws_secret_access_key" {
  type        = string
  description = "Secret key for LocalStack"
  default     = "test"
}

variable "primary_region" {
  type        = string
  description = "Primary AWS region"
  default     = "us-east-1"
}

variable "secondary_region" {
  type        = string
  description = "Secondary AWS region"
  default     = "us-west-2"
}

variable "localstack_endpoint" {
  type        = string
  description = "LocalStack edge endpoint"
  default     = "http://localstack:4566"
}

variable "name_prefix" {
  type        = string
  description = "Name prefix for resources"
  default     = "iac-sandbox"
}

variable "environment" {
  type        = string
  description = "Environment tag"
  default     = "dev"
}

variable "primary_vpc_cidr" {
  type        = string
  description = "Primary VPC CIDR"
  default     = "10.0.0.0/16"
}

variable "secondary_vpc_cidr" {
  type        = string
  description = "Secondary VPC CIDR"
  default     = "10.1.0.0/16"
}

variable "subnet_newbits" {
  type        = number
  description = "New bits to derive subnet masks from the VPC CIDR (e.g. /16 + 8 => /24)"
  default     = 8
}

variable "public_subnet_newbits" {
  type        = number
  description = "New bits to derive public subnet masks from the VPC CIDR (overrides subnet_newbits)"
  default     = null
}

variable "private_subnet_newbits" {
  type        = number
  description = "New bits to derive private subnet masks from the VPC CIDR (overrides subnet_newbits)"
  default     = null
}

variable "public_subnet_count" {
  type        = number
  description = "Number of public subnets to create (defaults to az_count)"
  default     = null
}

variable "private_subnet_count" {
  type        = number
  description = "Number of private subnets to create (defaults to az_count)"
  default     = null
}

variable "enable_private_subnets" {
  type        = bool
  description = "Create private subnets (and place app/RDS resources there when enabled)"
  default     = true
}

variable "simulate_unsupported" {
  type        = bool
  description = "Skip resources not supported by LocalStack Community"
  default     = true
}

variable "localstack_pro" {
  type        = bool
  description = "Enable LocalStack Pro-only resources when available"
  default     = false
}

variable "az_count" {
  type        = number
  description = "Number of availability zones to create per region"
  default     = 3
}

variable "app_instance_type" {
  type        = string
  description = "EC2 instance type for app servers"
  default     = "t3.micro"
}

variable "db_instance_class" {
  type        = string
  description = "RDS instance class"
  default     = "db.t3.micro"
}

variable "db_engine" {
  type        = string
  description = "RDS engine (mysql, mariadb, postgres)"
  default     = "mysql"
}

variable "db_engine_version" {
  type        = string
  description = "RDS engine version (empty lets AWS pick a default)"
  default     = "8.4.0"
}

variable "db_username" {
  type        = string
  description = "Database username"
  default     = "appuser"
}

variable "db_password" {
  type        = string
  description = "Database password"
  default     = "localstack123"
  sensitive   = true
}

variable "asg_min_size" {
  type        = number
  description = "Auto Scaling Group minimum size"
  default     = 3
}

variable "asg_max_size" {
  type        = number
  description = "Auto Scaling Group maximum size"
  default     = 6
}

variable "asg_desired_capacity" {
  type        = number
  description = "Auto Scaling Group desired capacity (used as instance count when full mode is disabled)"
  default     = 3
}

variable "alb_count" {
  type        = number
  description = "Number of ALBs per region"
  default     = 3
}

variable "enable_community_services" {
  type        = bool
  description = "Deploy LocalStack Community service resources"
  default     = true
}

variable "enable_lambda" {
  type        = bool
  description = "Enable Lambda in the community bundle (requires Docker for LocalStack)"
  default     = false
}

variable "enable_opensearch" {
  type        = bool
  description = "Enable OpenSearch domain in the community bundle"
  default     = false
}
