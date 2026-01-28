output "primary_vpc_id" {
  value = module.primary.vpc_id
}

output "secondary_vpc_id" {
  value = module.secondary.vpc_id
}

output "primary_public_subnet_ids" {
  value = module.primary.public_subnet_ids
}

output "secondary_public_subnet_ids" {
  value = module.secondary.public_subnet_ids
}

output "primary_private_subnet_ids" {
  value = module.primary.private_subnet_ids
}

output "secondary_private_subnet_ids" {
  value = module.secondary.private_subnet_ids
}

output "primary_alb_dns" {
  value = module.primary.alb_dns
}

output "secondary_alb_dns" {
  value = module.secondary.alb_dns
}

output "primary_bucket" {
  value = module.primary.bucket_name
}

output "secondary_bucket" {
  value = module.secondary.bucket_name
}

output "primary_rds_endpoint" {
  value = module.primary.rds_endpoint
}

output "secondary_rds_endpoint" {
  value = module.secondary.rds_endpoint
}

output "simulate_unsupported" {
  value = var.simulate_unsupported
}

output "localstack_endpoint" {
  value = var.localstack_endpoint
}
