locals {
  selected_engine = var.use_aurora ? var.engine_cluster : var.engine

  db_port = (
    contains(["mysql", "aurora-mysql"], local.selected_engine) ? 3306 : 5432
  )
}

resource "aws_db_subnet_group" "default" {
  name = "${var.name}-subnet-group"

  subnet_ids = var.publicly_accessible ? var.subnet_public_ids : var.subnet_private_ids

  tags = merge(var.tags, {
    Name = "${var.name}-subnet-group"
  })
}

resource "aws_security_group" "rds" {
  name        = "${var.name}-sg"
  description = "DB Security Group for ${var.name}"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow DB access"
    from_port   = local.db_port
    to_port     = local.db_port
    protocol    = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-sg"
  })
}
