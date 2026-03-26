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

  filter {
    name   = "availability-zone"
    values = ["us-east-1a", "us-east-1b", "us-east-1c"]
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
# Locals (Day 11 Core)
# -----------------------------

locals {
  is_production = var.environment == "production"

  instance_type     = local.is_production ? "t3.medium" : "t3.micro"
  min_size          = local.is_production ? 4 : 2
  max_size          = local.is_production ? 10 : 4
  enable_monitoring = local.is_production
}

# -----------------------------
# Security Groups
# -----------------------------

resource "aws_security_group" "alb" {
  name = "${var.cluster_name}-alb-sg"

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
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

resource "aws_security_group" "instance" {
  name = "${var.cluster_name}-instance-sg"

  ingress {
    from_port       = var.server_port
    to_port         = var.server_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
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
  instance_type = local.instance_type

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
  port     = var.server_port
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
  min_size         = local.min_size
  max_size         = local.max_size
  desired_capacity = local.min_size

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
  port              = var.server_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}

# -----------------------------
# Conditional Resource (Day 11)
# -----------------------------

resource "aws_cloudwatch_metric_alarm" "cpu" {
  count = local.enable_monitoring ? 1 : 0

  alarm_name          = "${var.cluster_name}-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80
}