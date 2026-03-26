Terraform AWS Webserver Cluster Module
🚀 Overview

This module provisions a highly available web server cluster on AWS using an Application Load Balancer (ALB), Auto Scaling Group (ASG), and EC2 instances. It is designed to be reusable across environments (dev, staging, production) using a single configuration driven by input variables and conditional logic.

The module automatically adjusts infrastructure size and features based on the environment, eliminating code duplication and improving maintainability.

🧱 What This Module Creates
Application Load Balancer (ALB)
Target Group with health checks
Auto Scaling Group (ASG)
Launch Template with Apache web server
Security Groups (ALB + EC2)
Optional CloudWatch CPU alarm (production only)
⚙️ Usage
module "webserver_cluster" {
  source = "github.com/calvince22/terraform-aws-webserver-cluster?ref=v0.0.4"

  cluster_name = "webservers-dev"
  environment  = "dev"
}
🌍 Multi-Environment Example
Dev
module "webserver_cluster" {
  source = "github.com/calvince22/terraform-aws-webserver-cluster?ref=v0.0.4"

  cluster_name = "webservers-dev"
  environment  = "dev"
}
Production
module "webserver_cluster" {
  source = "github.com/calvince22/terraform-aws-webserver-cluster?ref=v0.0.3"

  cluster_name = "webservers-production"
  environment  = "production"
}
🧠 How It Works

The module uses conditional logic via locals:

locals {
  is_production = var.environment == "production"

  instance_type     = local.is_production ? "t3.medium" : "t3.micro"
  min_size          = local.is_production ? 4 : 2
  max_size          = local.is_production ? 10 : 4
  enable_monitoring = local.is_production
}
Dev → smaller instances, fewer servers, no monitoring
Production → larger instances, more servers, monitoring enabled
📥 Inputs
Name	Description	Type	Default	Required
cluster_name	Name used for all resources	string	n/a	✅
environment	Deployment environment (dev, staging, production)	string	n/a	✅
server_port	Port for HTTP traffic	number	80	❌
📤 Outputs
Name	Description
alb_dns_name	DNS name of the load balancer
cpu_alarm_name	CloudWatch alarm name (null if disabled)
⚠️ Conditional Resources

This module uses:

count = condition ? 1 : 0

Example:

resource "aws_cloudwatch_metric_alarm" "cpu" {
  count = local.enable_monitoring ? 1 : 0
}

If monitoring is disabled, the resource is not created.

🔐 Input Validation
validation {
  condition     = contains(["dev", "staging", "production"], var.environment)
  error_message = "Environment must be dev, staging, or production."
}

Prevents invalid deployments at plan time.

⚠️ Gotchas
1. Conditional Outputs

When using count, always guard outputs:

value = local.enable_monitoring ? aws_cloudwatch_metric_alarm.cpu[0].alarm_name : null
2. AZ Availability Issues

Some instance types (e.g., t3.micro) may not be available in all Availability Zones. This module restricts subnets to:

us-east-1a, us-east-1b, us-east-1c
3. Module Versioning

Always pin your module version:

source = "github.com/calvince22/terraform-aws-webserver-cluster?ref=v0.0.4"
🏷️ Versioning Strategy
v0.0.3 → Stable production version
v0.0.4 → Environment-aware + conditional logic
Recommended Practice:
Dev → latest version
Production → pinned stable version
📌 Requirements
Terraform >= 1.0
AWS Provider >= 4.0
AWS account with proper IAM permissions
🧪 Deployment
terraform init
terraform plan
terraform apply
🧹 Cleanup
terraform destroy
📖 Key Concepts Demonstrated
Terraform Modules
Conditional Logic (? :)
count for optional resources
locals for clean architecture
Environment-based infrastructure
Versioned module sources