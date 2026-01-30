Multi-AZ Microservice ArchitectureA highly available, containerized microservice deployment engineered with Terraform, Docker, and AWS ECS. 

This project implements a Multi-AZ strategy to ensure fault tolerance and automated scalability.

Architecture Overview
The infrastructure is designed for 99.9% availability, utilizing two Availability Zones (AZs) within a custom VPC.

Networking: Custom VPC with Public/Private subnets across 2 AZs.Compute: AWS ECS (Elastic Container Service) running on EC2 instances.

Scaling: Auto Scaling Group (ASG) utilizing AWS Launch Templates for dynamic instance provisioning.

Traffic Management: Application Load Balancer (ALB) acting as the ingress point, routing traffic to Nginx-backed service containers.

Security: Principle of Least Privilege (PoLP) enforced via AWS IAM Roles and granular Security Groups.

Application: A Python-based microservice orchestrated with Docker and served via Nginx.


Tech Stack
Terraform (IaC)
Docker Orchestration
AWS ECS
Nginx
Python
AWS (VPC, IAM, ASG, ALB)




Key Features

1. High Availability (Multi-AZ)The infrastructure is spread across two distinct Availability Zones. If one AWS data center experiences an outage, the Application Load Balancer automatically reroutes traffic to the healthy nodes in the second AZ.

2. Infrastructure as Code (Terraform) The entire environment is version-controlled.
Modular Design: Clean separation of networking, security, and compute.
State Management: S3

3. Automated Scalability Using AWS Launch Templates and Auto Scaling Policies, the cluster scales based on CPU/Memory utilization, ensuring cost-efficiency during low traffic and stability during spikes.

4. Container Orchestration
Docker: Images are optimized for size and security.ECS: Manages the lifecycle of the Python containers, performing health checks and rolling updates.


Multi-AZ Microservice ArchitectureA highly available, containerized microservice deployment engineered with Terraform, Docker, and AWS ECS. 

This project implements a Multi-AZ strategy to ensure fault tolerance and automated scalability.

Architecture Overview
The infrastructure is designed for 99.9% availability, utilizing two Availability Zones (AZs) within a custom VPC.

Networking: Custom VPC with Public/Private subnets across 2 AZs.Compute: AWS ECS (Elastic Container Service) running on EC2 instances.

Scaling: Auto Scaling Group (ASG) utilizing AWS Launch Templates for dynamic instance provisioning.

Traffic Management: Application Load Balancer (ALB) acting as the ingress point, routing traffic to Nginx-backed service containers.

Security: Principle of Least Privilege (PoLP) enforced via AWS IAM Roles and granular Security Groups.

Application: A Python-based microservice orchestrated with Docker and served via Nginx.


🛠️ Tech Stack
Terraform (IaC)
Docker Orchestration
AWS ECS
Nginx
Python
AWS (VPC, IAM, ASG, ALB)




Key Features

1. High Availability (Multi-AZ)The infrastructure is spread across two distinct Availability Zones. If one AWS data center experiences an outage, the Application Load Balancer automatically reroutes traffic to the healthy nodes in the second AZ.

2. Infrastructure as Code (Terraform) The entire environment is version-controlled.
Modular Design: Clean separation of networking, security, and compute.
State Management: S3

3. Automated Scalability Using AWS Launch Templates and Auto Scaling Policies, the cluster scales based on CPU/Memory utilization, ensuring cost-efficiency during low traffic and stability during spikes.

4. Container Orchestration
Docker: Images are optimized for size and security.ECS: Manages the lifecycle of the Python containers, performing health checks and rolling updates.


🚀 Deployment Steps

Containerize the App:Bashdocker build -t microservice-app ./app

Initialize Infrastructure:Bash

cd terraform

terraform init

terraform plan

terraform apply -auto-approve

Access the Service:Once Terraform completes, it will output the ALB_DNS_Link.

Security IAM Roles: Task Execution Roles allow ECS to pull images from ECR without hardcoded credentials.

Private Isolation: The Python application sits in a private subnet, accessible only via the Load Balancer.

Maintained by Archibong Hashbury Looking to solve complex infrastructure challenges.


Access the Service:Once Terraform completes, it will output the ALB_DNS_Link.

Security IAM Roles: Task Execution Roles allow ECS to pull images from ECR without hardcoded credentials.

Private Isolation: The Python application sits in a private subnet, accessible only via the Load Balancer.

Maintained by Archibong Hashbury Looking to solve complex infrastructure challenges.
