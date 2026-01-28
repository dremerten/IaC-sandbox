output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  value = [for subnet in aws_subnet.public : subnet.id]
}

output "private_subnet_ids" {
  value = [for subnet in aws_subnet.private : subnet.id]
}

output "bucket_name" {
  value = aws_s3_bucket.app.id
}

output "alb_dns" {
  value = local.alb_dns
}

output "rds_endpoint" {
  value = local.rds_endpoint
}
