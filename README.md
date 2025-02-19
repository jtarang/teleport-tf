# Teleport: Terraform Infrastructure Setup

This repository contains Terraform configurations for setting up AWS resources and installing Teleport. 

## Prerequisites

Before running the Terraform scripts, ensure that you have the following:

- **Terraform**: Download Terraform and install it.
- **AWS CLI**: Install AWS CLI to interact with AWS services from the command line.
- **AWS Account**: Ensure you have access to an AWS account.
- **AWS Credentials**: Ensure your AWS credentials are properly configured.

## Steps to Deploy Infrastructure

### 1. Clone the Repository

Clone the repository to your local machine:

### 2. Create a tfvars file
```
cp -rv tf/tfvars/terraform.tfvars.tpl tf/tfvars/terraform.${USER}.tfvars
```

### 3. Terraform Apply

There are helper scripts in `scripts/local/tf-*.sh`
 
Run the follow command to apply
```
cd tf/aws/ && ../../scripts/local/tf-apply.sh
```

This should create the ssh key in `REPO_ROOT/.ssh` and the plan in `REPO_ROOT/tf/plans/`. 

### Clean Up Resources

Run the following command to destroy 

```
cd tf/aws/ && ../../scripts/local/tf-destroy.sh
```

This will remove all resources in the cloud, ssh keys and plans locally. 