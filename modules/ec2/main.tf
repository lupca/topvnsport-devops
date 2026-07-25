# Use existing security group instead of creating new one
data "aws_security_group" "app" {
  id = var.security_group_id
}

resource "aws_instance" "topvnsport" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [data.aws_security_group.app.id]

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
  }

  tags = merge(var.tags, {
    Name = var.name
  })

  lifecycle {
    ignore_changes = [ami, subnet_id, vpc_security_group_ids]
  }
}
