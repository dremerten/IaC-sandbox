variable "name_prefix" {
  type        = string
  description = "Base name prefix"
}

variable "component" {
  type        = string
  description = "Component name (primary/secondary)"
}

variable "environment" {
  type        = string
  description = "Environment tag"
}

variable "region" {
  type        = string
  description = "Region for this deployment"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR range"
}

variable "public_subnet_newbits" {
  type        = number
  description = "New bits to derive public subnet masks from the VPC CIDR"
  default     = 8
}

variable "private_subnet_newbits" {
  type        = number
  description = "New bits to derive private subnet masks from the VPC CIDR"
  default     = 8
}

variable "public_subnet_count" {
  type        = number
  description = "Number of public subnets to create"
  default     = 3
}

variable "private_subnet_count" {
  type        = number
  description = "Number of private subnets to create"
  default     = 3
}

variable "enable_private_subnets" {
  type        = bool
  description = "Create private subnets"
  default     = true
}

variable "simulate_unsupported" {
  type        = bool
  description = "Skip resources not supported by LocalStack Community"
}

variable "localstack_pro" {
  type        = bool
  description = "Enable LocalStack Pro-only resources when available"
  default     = false
}

variable "az_count" {
  type        = number
  description = "Number of availability zones to create"
  default     = 3
}

variable "azs" {
  type        = list(string)
  description = "Availability zones to use"
  default     = []
}

variable "alb_count" {
  type        = number
  description = "Number of ALBs per region"
  default     = 3
}

variable "app_instance_type" {
  type        = string
  description = "EC2 instance type for app servers"
}

variable "db_instance_class" {
  type        = string
  description = "RDS instance class"
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
}

variable "db_password" {
  type        = string
  description = "Database password"
  sensitive   = true
}

variable "asg_min_size" {
  type        = number
  description = "Auto Scaling Group minimum size"
}

variable "asg_max_size" {
  type        = number
  description = "Auto Scaling Group maximum size"
}

variable "asg_desired_capacity" {
  type        = number
  description = "Auto Scaling Group desired capacity"
}

variable "simulated_products" {
  type        = list(string)
  description = "Product names to use for simulated instances when full mode is disabled"
  default     = [
    "nginx",
    "redis",
    "postgres",
    "rabbitmq",
    "kafka",
    "vault",
    "grafana",
    "prometheus",
    "elasticsearch",
    "cassandra",
  ]
}

variable "tags" {
  type        = map(string)
  description = "Base tags to apply"
  default     = {}
}
