# AWS Terraform Scalable Infrastructure

This project demonstrates how to create a scalable and secure AWS infrastructure using Terraform. The infrastructure includes a Virtual Private Cloud (VPC) with public and private subnets, an Auto Scaling Group, a Load Balancer, and other essential resources. The project is designed to provide a high-availability environment with automated scaling capabilities.

## Table of Contents

- Overview
- Architecture
- Prerequisites
- Setup Instructions


## Overview

This project uses Terraform to provision an AWS infrastructure that includes:

- A VPC with public and private subnets across two availability zones.
- An Internet Gateway for internet access.
- Security Groups to control inbound and outbound traffic.
- An Auto Scaling Group with instances spread across private subnets.
- An Application Load Balancer to distribute incoming traffic across instances.
- A simple HTML file deployed on EC2 instances to demonstrate load balancing.

**Note:** This setup excludes NAT Gateways and S3 buckets, as they were not required for this specific use case.

## Architecture

The infrastructure is built across two availability zones for high availability and fault tolerance. Here is an overview of the architecture:

- **VPC:** A custom VPC with CIDR blocks assigned to public and private subnets.
- **Public Subnets:** Host the Application Load Balancer and Internet Gateway.
- **Private Subnets:** Host EC2 instances managed by an Auto Scaling Group.
- **Auto Scaling Group:** Automatically scales the number of instances based on demand.
- **Load Balancer:** Distributes incoming HTTP traffic across the EC2 instances in the Auto Scaling Group.

![VPC Example Private Subnets](https://github.com/Pankajs53/AWS-Terraform-Scalable-Infrastructure/blob/main/vpc-example-private-subnets.png)


## Basic Flow

- User: Initiates a request from the internet.
- Load Balancer DNS: The request is directed to the DNS name of the load balancer. (The load balancer is placed in a public subnet.)
- Internet Gateway: Allows the request from the internet to reach resources in the public subnet. It handles inbound and outbound traffic between the VPC and the internet.
- Route Table: The route table associated with the public subnet directs traffic to the Internet Gateway. This route table also governs how traffic is routed within the VPC.
- Public Subnet: Contains the load balancer. The load balancer receives the request from the internet through the Internet Gateway.
- Network Access Control List (NACL): Controls inbound and outbound traffic at the subnet level. For the public subnet, NACLs control traffic to and from the internet, and for the private subnet, they control traffic between subnets and the load balancer.
- Security Group: Attached to the load balancer and EC2 instances. It controls inbound and outbound traffic at the instance level. The load balancer's security group controls traffic to the EC2 instances, while the EC2 instances' security group controls traffic to and from the instances.
- Private Subnet: Where the EC2 instances might reside. The load balancer (in the public subnet) routes traffic to the EC2 instances in the private subnet.
- EC2 Instance: The final destination of the request, where it is processed.


## Prerequisites

Before deploying this infrastructure, ensure you have the following:

- An AWS account with necessary permissions to create the resources.
- Terraform installed on your local machine ([Install Terraform](https://www.terraform.io/downloads)).
- An existing SSH key pair in AWS for EC2 access.

## Setup Instructions

1. **Clone the Repository:**  
   ```bash
   git clone https://github.com/your-username/aws-terraform-scalable-infrastructure.git
   cd aws-terraform-scalable-infrastructure
2. **Configure AWS Credentials:**
Ensure your AWS credentials are configured. You can use the AWS CLI to configure them:
  ```bash
  aws configure

3. **Initialize Terraform:**
Initialize the Terraform working directory:
  ```bash
  terraform init

4. **Review and Edit Variables:**
Edit the variable.tf file to set your desired values, such as the VPC CIDR block, subnet CIDRs, and availability zones.

5. **Plan and Apply:**

  1. Generate an execution plan:
    ```bash
       terraform plan
  2. Apply the Terraform configuration to create the infrastructure:
  ```bash
  terraform apply


