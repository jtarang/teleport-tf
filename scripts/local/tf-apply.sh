TFVARS_FILE="../tfvars/terraform.${USER}.tfvars"

cd ../../tf/aws && \
terraform init && \
terraform validate && \
terraform plan -var-file="${TFVARS_FILE}" -out "../plans/${USER}-sales-eng.plan" # sfd && \
#terraform apply "../plans/${USER}-sales-eng.plan" && \
