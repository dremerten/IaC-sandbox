output "bucket_name" {
  value = aws_s3_bucket.this.id
}

output "object_key" {
  value = aws_s3_object.object.key
}
