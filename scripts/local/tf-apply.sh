TFVARS_FILE="terraform.${USER}.tfvars"

cd ../../tf/aws && \
terraform init && \
terraform validate && \
terraform plan -var-file="${TFVARS_FILE}" -out "${USER}-sales-eng.plan" && \
terraform apply jt-sales-eng.plan -var-file="${TFVARS_FILE}"
