variable "cluster_name" {
  description = "Name used for tagging and naming resources"
  type        = string
}
variable "enable_http" {
  description = "Enable HTTP traffic"
  type        = bool
  default     = true
}
variable "environment" {
  description = "Deployment environment"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be dev, staging, or production."
  }
}

variable "server_port" {
  description = "Application port"
  type        = number
  default     = 80
}