terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  
  backend "s3" {
   
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

locals {
  name_prefix = "${var.prefix}"
}

module "ecs" {
  source = "./modules/ecs"
  
  prefix      = local.name_prefix
  environment = var.environment
}

module "ecs_task" {
  source = "./modules/ecs-task"
  
  prefix = var.prefix
  environment = var.environment
  aws_region = var.aws_region
  image_name_passed_as_parameter = var.image_name_passed_as_parameter
}

module "ecs_service" {
  source = "./modules/ecs-service"
  
  prefix      = local.name_prefix
  environment = var.environment
  
  cluster_id        = module.ecs.cluster_id
  task_definition_arn = module.ecs_task.task_definition_arn
  aws_region = var.aws_region
} 

