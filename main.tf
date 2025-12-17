terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.26.0"
    }
  }
}

provider "aws" {
  # Configuration options
}






### Define the Network in 2 AZs
resource "aws_vpc" "main" { cidr_block = "10.0.0.0/16" }

resource "aws_subnet" "az_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}

#### availability_zone_2 
resource "aws_subnet" "az_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
}

#### Create the Load Balancer (Layer 7)
resource "aws_lb" "web_lb" {
  name               = "web-service-lb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.az_1.id, aws_subnet.az_2.id]
}

#### Create the Target Group with the Health Check
resource "aws_lb_target_group" "web_tg" {
  name     = "web-service-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/health"  # The crucial part!
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"      # Must return HTTP 200
  }
}