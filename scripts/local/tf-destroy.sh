TFVARS_FILE="tfvars/terraform.${USER}.tfvars"
eval "$(tctl terraform env)"   

export TF_VAR_teleport_address="$TF_TELEPORT_ADDR"      
export TF_VAR_teleport_identity_file_base64="$TF_TELEPORT_IDENTITY_FILE_BASE64"

cd ../tf && \
terraform init -upgrade
terraform destroy -var-file="${TFVARS_FILE}" --auto-approve && \
rm -r .terraform && \
rm .terraform.lock.hcl && \
rm terraform.tfstate && \
rm terraform.tfstate.backup && \
rm "plans/${USER}-sales-eng.plan"
