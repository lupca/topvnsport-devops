output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.topvnsport.id
}

output "public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.topvnsport.public_ip
}

output "security_group_id" {
  description = "ID of the application security group"
  value       = data.aws_security_group.app.id
}
