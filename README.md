# Teleport: Terraform Infrastructure Setup

This repository contains Terraform configurations for setting up AWS resources and installing Teleport. 

## Prerequisites

Before running the Terraform scripts, ensure that you have the following:

- **Terraform**: Download Terraform and install it.
- **AWS CLI**: Install AWS CLI to interact with AWS services from the command line.
- **AWS Account**: Ensure you have access to an AWS account.
- **AWS Credentials**: Ensure your AWS credentials are properly configured.

### Module Descriptions

- **vpc**: Configures the Virtual Private Cloud (VPC) resources including the CIDR block, DNS support, and hostnames.
- **subnet**: Creates public and private subnets within the VPC.
- **security_group**: Defines security groups such as allowing SSH access from a specific IP address.
- **launch_template**: Creates an EC2 launch template with specific configuration, including user-data to install and configure software on the EC2 instance.
- **ec2_instance**: Defines the EC2 instances using the launch template to deploy the instances with the desired configurations.

## Steps to Deploy Infrastructure

### 1. Clone the Repository

Clone the repository to your local machine:

### 2. Create a tfvars file
`tf/tfvars/terraform.${USER}.tfvars`

### 3. Terraform Apply

There are helper scripts in `scripts/local/tf-*.sh`
Run `cd tf/aws/ && ../../scripts/local/tf-apply.sh`

This should create the ssh key in `REPO_ROOT/.ssh` and the plan in `REPO_ROOT/tf/plans/`. 

### Clean Up Resources

Run `cd tf/aws/ && ../../scripts/local/tf-destroy.sh`
This will remove all resources in the cloud, ssh keys and plans locally. 