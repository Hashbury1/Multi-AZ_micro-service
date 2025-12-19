provider "aws" {
  region = "us-east-1"
}

#. Fetch the Latest ECS-Optimized AMI (This is the "Brain" for your EC2)
data "aws_ami" "ecs_optimized" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }
}

#. Networking (VPC & 2 Public Subnets for HA)
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "pub_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}


# AWS subnet config
resource "aws_subnet" "pub_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
}


#. IAM Role (Allows your EC2 to "talk" to the ECS Cluster)
resource "aws_iam_role" "ecs_agent" {
  name = "ecs-agent-role"
  assume_role_policy = jsonencode({
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "ec2.amazonaws.com" } }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_agent" {
  role       = aws_iam_role.ecs_agent.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_agent" {
  name = "ecs-agent-profile"
  role = aws_iam_role.ecs_agent.name
}


#. The ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "free-tier-cluster"
}

#. Launch Template & Auto Scaling (The "Free" Servers)
resource "aws_launch_template" "ecs_lt" {
  name_prefix   = "ecs-template-"
  image_id      = data.aws_ami.ecs_optimized.id
  instance_type = "t3.micro" # <--- Free Tier eligible
  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_agent.name
  }
}


resource "aws_autoscaling_group" "ecs_asg" {
  vpc_zone_identifier = [aws_subnet.pub_1.id, aws_subnet.pub_2.id]
  desired_capacity    = 1 # One server in each AZ for HA
  max_size            = 2
  min_size            = 1
  launch_template {
    id      = aws_launch_template.ecs_lt.id
    version = "$Latest"
  }
}


#. Load Balancer (ALB)
resource "aws_lb" "main" {
  name    = "app-lb"
  subnets = [aws_subnet.pub_1.id, aws_subnet.pub_2.id]
}


#config for target group
resource "aws_lb_target_group" "app_tg" {
  name        = "app-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"
  health_check {
    path    = "/health"
    matcher = "200"
  }
}


# listener config
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# The ECS Service
resource "aws_ecs_service" "app" {
  name            = "event-monitor-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  launch_type     = "EC2"
  desired_count   = 2

  load_balancer {
    target_group_arn = aws_lb_target_group.app_tg.arn
    container_name   = "flask-app"
    container_port   = 8080
  }
}

resource "aws_ecs_task_definition" "app" {
  family = "flask-event-monitor-task"
  # ... other task settings ...

  container_definitions = jsonencode([{
    name  = "flask-app"
    image = "${var.aws_account_id}.dkr.ecr.us-east-1.amazonaws.com/flask-event-monitor:latest"
    
    # ADD THESE TWO LINES
    memory            = 512  # Hard limit (container killed if exceeded)
    memoryReservation = 256  # Soft limit (guaranteed amount)

    portMappings = [{
      containerPort = 8080
      hostPort      = 8080
    }]
  }])
}