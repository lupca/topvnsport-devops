variable "name" {
  description = "Name for the instance"
  type        = string
}

variable "ami_id" {
  description = "AMI ID"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "EC2 key pair name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID (required if creating new security group)"
  type        = string
  default     = ""
}

variable "subnet_id" {
  description = "Subnet ID to launch the instance in"
  type        = string
}

variable "existing_security_group_id" {
  description = "Existing security group ID. If empty, creates new one."
  type        = string
  default     = ""  # Empty = create new
}

variable "root_volume_size" {
  description = "Root EBS volume size in GB"
  type        = number
  default     = 30
}

variable "ingress_rules" {
  description = "Ingress rules (only used when creating new SG)"
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [
    { description = "SSH", from_port = 22, to_port = 22, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] },
    { description = "HTTP", from_port = 80, to_port = 80, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] },
    { description = "HTTPS", from_port = 443, to_port = 443, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] },
  ]
}

variable "tags" {
  description = "Tags"
  type        = map(string)
  default     = {}
}
