variable "cluster_name" {
  description = "Name used for tagging and naming resources"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "min_size" {
  description = "Minimum number of instances"
  type        = number
}

variable "max_size" {
  description = "Maximum number of instances"
  type        = number
}

variable "server_port" {
  description = "Application port"
  type        = number
  default     = 80
}

variable "enable_http" {
  description = "Enable HTTP traffic"
  type        = bool
  default     = true
}