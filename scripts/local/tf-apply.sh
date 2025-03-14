TFVARS_FILE="tfvars/terraform.${USER}.tfvars"
eval "$(tctl terraform env)"   

export TF_VAR_teleport_address="$TF_TELEPORT_ADDR"      
export TF_VAR_teleport_identity_file_base64="$TF_TELEPORT_IDENTITY_FILE_BASE64"

cd ../tf && \
terraform init -upgrade && \
terraform validate && \
terraform plan -var-file="${TFVARS_FILE}" -out "plans/${USER}-sales-eng.plan" && \
terraform apply "plans/${USER}-sales-eng.plan"
