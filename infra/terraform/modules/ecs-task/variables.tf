variable "prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "aws_region" {
  description = "AWS region to deploy to"
  type        = string
} 

variable "image_name_passed_as_parameter" {
  description = "The ECR repository path for the container image"
  type        = string
}