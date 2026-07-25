output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.topvnsport.id
}

output "public_ip" {
  description = "Public IP address"
  value       = aws_instance.topvnsport.public_ip
}

output "security_group_id" {
  description = "Security group ID (created or existing)"
  value       = local.security_group_id
}
