variable "enable" {
  type        = bool
  description = "Enable community service resources"
}

variable "enable_lambda" {
  type        = bool
  description = "Enable Lambda resources (requires Docker for LocalStack)"
  default     = false
}

variable "enable_opensearch" {
  type        = bool
  description = "Enable OpenSearch domain (requires download)"
  default     = false
}

variable "name_prefix" {
  type        = string
  description = "Base name prefix"
}

variable "component" {
  type        = string
  description = "Component name (primary/secondary)"
}

variable "region" {
  type        = string
  description = "Region for this deployment"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for network-scoped resources"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Public subnet IDs"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs (may be empty)"
  default     = []
}

variable "bucket_name" {
  type        = string
  description = "S3 bucket name to use for service artifacts"
}

variable "tags" {
  type        = map(string)
  description = "Base tags to apply"
  default     = {}
}
