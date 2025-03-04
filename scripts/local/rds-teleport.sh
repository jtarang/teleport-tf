TELEPORT_DOMAIN="nebula-dash-staging.cloud.gravitational.io"
TELEPORT_VERSION="$(curl https://$TELEPORT_DOMAIN/v1/webapi/ping | jq -r '.server_version')"
RDS_DB_NAME="jasmit-se-demo-rds"
RDS_PROTOCOL="postgres"
RDS_USERNAME="jasmit"
RDS_ENDPOINT="jasmit-psql-rds.c0m0dsney9i9.us-west-1.rds.amazonaws.com"
RDS_ENDPOINT_PORT="5432"

### Attach proper IAM to EC2 Instance


### Run on RDS
### GRANT rds_iam TO ${RDS_USERNAME};



### Run locally
tctl tokens add --type=node,db --format json >> token.json

teleport db configure create \
   --name=${RDS_DB_NAME} \
   --proxy=${TELEPORT_DOMAIN}:443  \
   --protocol=${RDS_PROTOCOL} \
   --uri=${RDS_ENDPOINT}:${RDS_ENDPOINT_PORT} \
   --labels=env=staging \
   --token=token.json

### Copy the config over to EC2

### Run on EC2
### sudo systemctl enable teleport"
### sudo systemctl start teleport"

# Run this on EC2 to enable the Metadata service
# # Get the session token (IMDSv2)

# SESSION_TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
# echo "Session Token: $SESSION_TOKEN"

# # Get IAM role information using the session token
# IAM_INFO=$(curl -H "X-aws-ec2-metadata-token: $SESSION_TOKEN" "http://169.254.169.254/latest/meta-data/iam/info")


# echo "IAM Info: $IAM_INFO"

# sudo systemctl stop teleport
# sudo systemctl start teleport
# sleep 10
# sudo systemctl status teleport