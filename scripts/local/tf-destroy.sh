cd ../../tf/aws
terraform destroy --auto-approve
rm -r .terraform
rm .terraform.lock.hcl
rm terraform.tfstate
rm terraform.tfstate.backup
rm jt-sales-eng.plan