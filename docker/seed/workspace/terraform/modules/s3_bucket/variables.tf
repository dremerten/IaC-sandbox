variable "bucket_name" {
  type        = string
  description = "S3 bucket name"
}

variable "object_key" {
  type        = string
  description = "S3 object key"
}

variable "object_source" {
  type        = string
  description = "Path to object file"
}
