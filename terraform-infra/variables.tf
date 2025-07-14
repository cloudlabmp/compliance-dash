variable "aws_region" {
  description = "AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "openai_api_key" {
  description = "OpenAI API key for backend"
  type        = string
}
