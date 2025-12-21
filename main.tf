provider "aws" {
  region = "us-east-1"
}

# 1. VPC & Subnets
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "pub_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "pub_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
}

# 2. Internet Gateway & Routing
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.pub_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.pub_2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "ecs_sg" {
  name   = "ecs-sg"
  vpc_id = aws_vpc.main.id

  # THIS IS THE MISSING PIECE: Allow public web traffic
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  # Allow the Load Balancer to talk to your Flask App (Dynamic Ports)
  ingress {
    from_port   = 32768
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 4. IAM Roles for ECS Nodes (EC2 Instances)
resource "aws_iam_role" "ecs_agent" {
  name = "ecs-agent-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ 
      Action = "sts:AssumeRole", 
      Effect = "Allow", 
      Principal = { Service = "ec2.amazonaws.com" } 
    }]
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

# 5. ECS Cluster & AMI Look-up
resource "aws_ecs_cluster" "main" {
  name = "free-tier-cluster"
}

data "aws_ami" "ecs_optimized" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-ecs-hvm-*-x86_64"]
  }
}

# 6. Launch Template
resource "aws_launch_template" "ecs_lt" {
  name_prefix   = "ecs-template-"
  image_id      = data.aws_ami.ecs_optimized.id
  instance_type = "t3.micro"

  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo ECS_CLUSTER=${aws_ecs_cluster.main.name} >> /etc/ecs/ecs.config
    echo ECS_ENABLE_CONTAINER_METADATA=true >> /etc/ecs/ecs.config
  EOF
  )

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_agent.name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.ecs_sg.id]
  }

  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    http_endpoint               = "enabled"
  }

  tag_specifications {
    resource_type = "instance"
    tags = { Name = "ecs-container-instance" }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# 7. Auto Scaling Group
resource "aws_autoscaling_group" "ecs_asg" {
  vpc_zone_identifier = [aws_subnet.pub_1.id, aws_subnet.pub_2.id]
  desired_capacity    = 2
  max_size            = 2
  min_size            = 1
  launch_template {
    id      = aws_launch_template.ecs_lt.id
    version = "$Latest"
  }
  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = true
  }
}

# 8. Load Balancer & Target Group
resource "aws_lb" "main" {
  name               = "app-lb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.pub_1.id, aws_subnet.pub_2.id]
  security_groups    = [aws_security_group.ecs_sg.id] # Re-using SG for simplicity; usually ALB has its own
}


# Target group config
resource "aws_lb_target_group" "app_tg" {
  name        = "app-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    path                = "/health"
    matcher             = "200"
    port                = "traffic-port" # <--- IMPORTANT: Change this from 8080 to "traffic-port"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

resource "aws_ecs_task_definition" "app" {
  family = "flask-event-monitor-task"
  container_definitions = jsonencode([{
    name      = "flask-app"
    image     = "${var.aws_account_id}.dkr.ecr.us-east-1.amazonaws.com/flask-event-monitor:latest"
    memory    = 512
    # ... other settings ...
    portMappings = [{
      containerPort = 8080
      hostPort      = 0  # <--- CHANGE THIS TO 0
    }]
  }])
}

resource "aws_ecs_service" "app" {
  name            = "event-monitor-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  launch_type     = "EC2"
  desired_count   = 2
  health_check_grace_period_seconds = 60
  
  load_balancer {
    target_group_arn = aws_lb_target_group.app_tg.arn
    container_name   = "flask-app" # Must match name in Task Definition
    container_port   = 8080        # The port inside the container
  }
}