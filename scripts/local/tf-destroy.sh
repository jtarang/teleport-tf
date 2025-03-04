TFVARS_FILE="tfvars/terraform.${USER}.tfvars"

cd ../tf && \
terraform destroy -var-file="${TFVARS_FILE}" --auto-approve && \
rm -r .terraform && \
rm .terraform.lock.hcl && \
rm terraform.tfstate && \
rm terraform.tfstate.backup && \
rm "plans/${USER}-sales-eng.plan"
