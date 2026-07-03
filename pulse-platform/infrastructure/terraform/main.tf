terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  default = "us-east-1"
}

variable "environment" {
  default = "dev"
}

variable "project" {
  default = "pulse"
}

# VPC Module (placeholder — wire to terraform-aws-modules/vpc in production)
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project}-${var.environment}-vpc"
    Environment = var.environment
  }
}

# RDS PostgreSQL
resource "aws_db_subnet_group" "main" {
  name       = "${var.project}-${var.environment}-db"
  subnet_ids = [] # Wire to private subnets

  tags = {
    Environment = var.environment
  }
}

resource "aws_db_instance" "postgres" {
  identifier           = "${var.project}-${var.environment}-postgres"
  engine               = "postgres"
  engine_version       = "16"
  instance_class       = "db.r6g.large"
  allocated_storage    = 100
  storage_encrypted    = true
  db_name              = "pulse"
  username             = "pulse"
  password             = var.db_password
  db_subnet_group_name = aws_db_subnet_group.main.name
  skip_final_snapshot  = var.environment == "dev"

  tags = {
    Environment = var.environment
  }
}

variable "db_password" {
  sensitive = true
}

# ElastiCache Redis
resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "${var.project}-${var.environment}-redis"
  engine               = "redis"
  node_type            = "cache.r6g.large"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379

  tags = {
    Environment = var.environment
  }
}

# S3 for assets and exports
resource "aws_s3_bucket" "assets" {
  bucket = "${var.project}-${var.environment}-assets"

  tags = {
    Environment = var.environment
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "assets" {
  bucket = aws_s3_bucket.assets.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

output "postgres_endpoint" {
  value = aws_db_instance.postgres.endpoint
}

output "redis_endpoint" {
  value = aws_elasticache_cluster.redis.cache_nodes[0].address
}

output "assets_bucket" {
  value = aws_s3_bucket.assets.bucket
}
