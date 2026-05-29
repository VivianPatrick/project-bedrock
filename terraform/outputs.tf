output "cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "region" {
  description = "AWS region"
  value       = var.region
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

# Uncomment after s3.tf is added
# output "assets_bucket_name" {
#   description = "S3 assets bucket name"
#   value       = aws_s3_bucket.assets.bucket
# }