# EC2 Module - supports both "create new" and "use existing" patterns

# Security Group: create new OR use existing
resource "aws_security_group" "app" {
  count       = var.existing_security_group_id == "" ? 1 : 0
  name        = "${var.name}-app-sg"
  description = "Security group for ${var.name}"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      description = ingress.value.description
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name}-app-sg" })
}

data "aws_security_group" "existing" {
  count = var.existing_security_group_id != "" ? 1 : 0
  id    = var.existing_security_group_id
}

locals {
  security_group_id = var.existing_security_group_id != "" ? data.aws_security_group.existing[0].id : aws_security_group.app[0].id
}

# EC2 Instance
resource "aws_instance" "topvnsport" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [local.security_group_id]

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
  }

  tags = merge(var.tags, { Name = var.name })

  lifecycle {
    ignore_changes = [ami]
  }
}
