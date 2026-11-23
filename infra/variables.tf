variable "aws_region" {
  description = "AWS Region for the CRC infrastructure."
  type        = string
  default     = "eu-central-1"
}

variable "environment" {
  description = "Environment name for the deployment."
  type        = string
  default     = "prod"
}