variable "name" {
  description = "Name prefix for VPC resources"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC (must match the existing VPC being imported)"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets (must match the existing subnets being imported)"
  type        = list(string)
}

variable "availability_zones" {
  description = "Availability zones for the public subnets, one per entry in public_subnet_cidrs"
  type        = list(string)
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
