# Enterprise Cloud Architecture & Infrastructure Portfolio

Welcome to my central Cloud Engineering portfolio. This repository serves as a curated showcase of production-ready, highly available, and secure cloud infrastructure blueprints. 

While the primary focus centers on automating complex topologies using **Terraform (Infrastructure as Code)** within **Amazon Web Services (AWS)**, this portfolio is an evolving ecosystem. It features diverse projects demonstrating modern DevOps methodologies, Cloud-Native patterns, Containerization, Serverless architectures, and CI/CD automation.

---

## 🎯 Portfolio Vision & Engineering Principles

This repository is designed to demonstrate hands-on expertise in implementing the **AWS Well-Architected Framework** and modern DevOps practices. Every architecture hosted here is built from the ground up with a focus on eliminating manual configuration (ClickOps) and adhering to strict enterprise engineering principles:

* **Infrastructure as Code (IaC) & Idempotency:** Utilizing modular, reusable, and dry Terraform configurations to ensure deterministic deployments across multiple environments (Dev/Staging/Prod).
* **Zero-Trust Security & Compliance:** Implementing strict network isolation (Least Privilege routing), fine-grained IAM policies, secure VPC endpoints, and robust automated secret management.
* **High Availability (HA) & Fault Tolerance:** Designing self-healing infrastructures utilizing Multi-AZ deployments, resilient load balancing, and dynamic auto-scaling policies capable of handling production-scale traffic.
* **State Management & Concurrency:** Enforcing secure remote state backends with state-locking mechanisms to mimic enterprise-level team collaboration and prevent race conditions.
* **Observability & Cost Optimization:** Right-sizing cloud resources and incorporating monitoring hooks to ensure financial efficiency without sacrificing performance or reliability.

---

## 🗂️ Portfolio Projects Index

| Project | Description | Tech Stack | Status |
| :--- | :--- | :--- | :--- |
| **[Project 1: Highly Available 3-Tier VPC Architecture](#-project-1-aws-3-tier-cloud-architecture)** | Production-ready 3-tier web infrastructure spanning multiple Availability Zones with automated failover. | AWS VPC, CloudFront, ALB, ASG, RDS PostgreSQL, Secrets Manager, S3 Remote State | 🟢 Completed |
| *Project 2: Containerized Cloud Native App (Coming Soon)* | Microservices orchestration with automated CI/CD pipeline deployment. | AWS EKS (Kubernetes), Docker, AWS ECR, GitHub Actions, Helm | 🟡 Planning |
| *Project 3: Serverless Event-Driven Architecture (Coming Soon)* | Cost-efficient, scale-to-zero backend processing pipeline. | AWS Lambda, API Gateway, DynamoDB, Amazon SQS/SNS | 🟡 Planning |

---

## 🏗️ Project 1: AWS 3-Tier Cloud Architecture

The inaugural project focuses on deploying a classic, production-ready **3-Tier Cloud Architecture** inside a custom Virtual Private Cloud (VPC) to ensure top-tier segregation between web, application, and database components.

### 📊 Architecture Diagram
The cloud blueprint automated by Terraform in this project is based on the comprehensive design:

<img width="1697" height="927" alt="Screenshot 2026-06-27 161804_edited" src="https://github.com/user-attachments/assets/c6aa5575-ceae-4383-a887-7ffe4ab06286" />

### 🔍 Tier-by-Tier Breakdown
The infrastructure spans across two Availability Zones (`us-east-1a` & `us-east-1b`) ensuring High Availability (HA) and Fault Tolerance:

1. **Layer 1: Public Subnets (Web / Routing Tier)**
   * **Amazon CloudFront & ACM:** Low-latency global content delivery (CDN) paired with secure SSL/TLS certificates managed via AWS Certificate Manager.
   * **Application Load Balancer (ALB):** Intelligently routes incoming public traffic from the Internet Gateway (IGW) to the application instances in the private layer.
   * **NAT Gateways (A & B):** Provisioned in each public subnet to allow safe, outbound-only internet access for private resources (e.g., application patches/updates).
   * **AWS Systems Manager (SSM) Endpoint:** Enables secure infrastructure management and secure terminal access without exposing SSH keys or relying on a vulnerable Bastion Host.

2. **Layer 2: Private Subnets (Application Tier)**
   * **Auto Scaling Group (ASG):** Dynamically provisions and scales EC2 web application instances up or down based on metrics like CPU utilization or traffic load.
   * **Enhanced Security:** Application instances remain completely isolated from the open internet, accepting traffic exclusively forwarded by the ALB.

3. **Layer 3: Isolated Subnets (Database Tier)**
   * **Amazon RDS for PostgreSQL:** The primary database is configured with **Synchronous Multi-AZ Replication** to a standby instance in `us-east-1b` for automatic, instant failover.
   * **Read Replicas:** Employs asynchronous replication to offload read-only traffic and boost system-wide database performance.
   * **AWS Secrets Manager:** Automates database credential management with automated password rotation and secure encryption, removing hardcoded secrets from the code.

---

## 🛠️ Remote State & Terraform Workflow

To ensure state integrity and professional development standards, the workflow is strictly defined as follows (and visualized in **Screenshot 2026-06-27 161804_edited.png**):
1. **Local Machine:** Infrastructure code is written and tested locally.
2. **GitHub:** Version control acts as the source of truth for the configuration code.
3. **Amazon S3 (`terraform.tfstate`):** The Terraform State file is stored remotely in an S3 Bucket. DynamoDB state-locking features are integrated to prevent concurrent execution conflicts or race conditions.

---
