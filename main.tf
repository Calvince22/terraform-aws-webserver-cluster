provider "aws" {
  region = "us-east-1"
}

# -----------------------------
# Data Sources
# -----------------------------
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ami" "ubuntu_22_04" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  owners = ["099720109477"]
}

# -----------------------------
# Security Groups
# -----------------------------

# ALB Security Group
resource "aws_security_group" "alb" {
  name = "${var.cluster_name}-alb-sg"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Instance Security Group
resource "aws_security_group" "instance" {
  name = "${var.cluster_name}-instance-sg"

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id] # Only allow ALB
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# -----------------------------
# Launch Template
# -----------------------------
resource "aws_launch_template" "example" {
  name_prefix   = var.cluster_name
  image_id      = data.aws_ami.ubuntu_22_04.id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.instance.id]

  user_data = base64encode(<<-EOF
              #!/bin/bash
              apt update -y
              apt install -y apache2
              echo "Hello from ${var.cluster_name}" > /var/www/html/index.html
              systemctl start apache2
              systemctl enable apache2
              EOF
  )
}

# -----------------------------
# Target Group
# -----------------------------
resource "aws_lb_target_group" "asg" {
  name     = "${var.cluster_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path     = "/"
    protocol = "HTTP"
    matcher  = "200"
    interval = 15
    timeout  = 5
  }
}

# -----------------------------
# Auto Scaling Group
# -----------------------------
resource "aws_autoscaling_group" "example" {
  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.min_size

  vpc_zone_identifier = data.aws_subnets.default.ids

  target_group_arns = [aws_lb_target_group.asg.arn]

  launch_template {
    id      = aws_launch_template.example.id
    version = "$Latest"
  }
}

# -----------------------------
# Load Balancer
# -----------------------------
resource "aws_lb" "example" {
  name               = var.cluster_name
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default.ids
  security_groups    = [aws_security_group.alb.id]
}

# -----------------------------
# Listener
# -----------------------------
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}