variable "services" {
  description = "Map of services to build. Keys are service names; values are objects with context and dockerfile fields."
  type = map(object({
    context    = string
    dockerfile = string
  }))
}

variable "tag_suffix" {
  description = "String appended to image tag to force rebuilds"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}
