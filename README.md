
# Multi-AZ Microservice Architecture

A highly available, containerized microservice deployment engineered with **Terraform**, **Docker**, and **AWS ECS**. This project implements a Multi-AZ strategy to ensure fault tolerance and automated scalability.

## Architecture Overview

The infrastructure is designed for **99.9% availability**, utilizing two Availability Zones (AZs) within a custom VPC.

* **Networking:** Custom VPC with Public/Private subnets across 2 AZs.
* **Compute:** AWS ECS (Elastic Container Service) running on EC2 instances.
* **Scaling:** Auto Scaling Group (ASG) utilizing AWS Launch Templates for dynamic instance provisioning.
* **Traffic Management:** Application Load Balancer (ALB) acting as the ingress point, routing traffic to Nginx-backed service containers.
* **Security:** Principle of Least Privilege (PoLP) enforced via AWS IAM Roles and granular Security Groups.
* **Application:** A Python-based microservice orchestrated with Docker and served via Nginx.

---

## Tech Stack

| Category | Technology |
| --- | --- |
| **Cloud Provider** | AWS (VPC, IAM, ASG, ALB) |
| **Infrastructure** | Terraform (IaC) |
| **Orchestration** | AWS ECS |
| **Containerization** | Docker |
| **Web Server** | Nginx |
| **Language** | Python |

---

## Key Features

### 1. High Availability (Multi-AZ)

The infrastructure is spread across two distinct Availability Zones. If one AWS data center experiences an outage, the Application Load Balancer automatically reroutes traffic to the healthy nodes in the second AZ.

### 2. Infrastructure as Code (Terraform)

The entire environment is version-controlled and reproducible.

* **Modular Design:** Clean separation of networking, security, and compute modules.
* **State Management:** Remote state storage via S3.

### 3. Automated Scalability

Using AWS Launch Templates and Auto Scaling Policies, the cluster scales based on CPU/Memory utilization, ensuring cost-efficiency during low traffic and stability during spikes.

### 4. Container Orchestration

* **Docker:** Images are optimized for size and security.
* **ECS:** Manages the lifecycle of the Python containers, performing health checks and rolling updates.

---

## Deployment Steps

### 1. Containerize the App

```bash
docker build -t microservice-app ./app

```

### 2. Initialize Infrastructure

```bash
cd terraform
terraform init
terraform plan
terraform apply -auto-approve

```

### 3. Access the Service

Once Terraform completes, it will output the `ALB_DNS_Link`. Copy this into your browser to view the running application.

---

##  Security & Isolation

* **IAM Roles:** Task Execution Roles allow ECS to pull images from ECR without hardcoded credentials.
* **Private Isolation:** The Python application resides in a private subnet, shielded from the public internet and accessible only via the Load Balancer.

---

**Maintained by Archibong Hashbury** *Looking to solve complex infrastructure challenges.*

---

Would you like me to add a **"Prerequisites"** section (like AWS CLI or Terraform versions) or a **"Project Structure"** tree to this README?
