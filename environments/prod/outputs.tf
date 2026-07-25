output "vpc_id" {
  description = "ID of the production VPC"
  value       = module.vpc.vpc_id
}

output "ec2_instance_id" {
  description = "ID of the topvnsport EC2 instance"
  value       = module.ec2.instance_id
}

output "ec2_public_ip" {
  description = "Public IP of the topvnsport EC2 instance"
  value       = module.ec2.public_ip
}

output "rds_cluster_endpoint" {
  description = "Writer endpoint of the Aurora PostgreSQL cluster"
  value       = module.rds.cluster_endpoint
}

output "s3_bucket_name" {
  description = "Name of the assets S3 bucket"
  value       = module.s3.bucket_id
}
