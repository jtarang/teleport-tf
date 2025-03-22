#!/bin/bash

set +x

# Get Info Label Scripts
sudo yum -y update
sudo yum -y install git nmap jq
git clone https://github.com/jtarang/teleportinfolabels.git /tmp/info_lables
cd /tmp/info_lables && sudo chmod +x *.sh 
cd /tmp/info_lables && sudo cp -rv *.sh /usr/local/bin/


sudo amazon-linux-extras install nginx1.12
sudo systemctl start nginx
sudo systemctl enable nginx
sudo systemctl status nginx 

SESSION_TOKEN=$(curl -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" -X PUT "http://169.254.169.254/latest/api/token")
INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $SESSION_TOKEN" -s http://169.254.169.254/latest/meta-data/instance-id)
REGION=$(curl -H "X-aws-ec2-metadata-token: $SESSION_TOKEN" -s http://169.254.169.254/latest/meta-data/placement/region)

sudo yum -y remove awscli
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update
/usr/local/bin/aws ec2  delete-tags --resources $INSTANCE_ID --tags Key="teleport.dev/creator"
/usr/local/bin/aws ec2 create-tags --resources $INSTANCE_ID   --tags Key=InstanceID,Value=$INSTANCE_ID
/usr/local/bin/aws ec2 modify-instance-metadata-options --instance-id $INSTANCE_ID --http-endpoint enabled --instance-metadata-tags enabled  --region $REGION

RANDOM_SUFFIX=$(openssl rand -base64 2 | tr -dc 'a-zA-Z0-9' | tr '[:upper:]' '[:lower:]')
sudo hostnamectl set-hostname "${EC2_INSTANCE_NAME}-$RANDOM_SUFFIX"

TELEPORT_VERSION="$(curl https://${TELEPORT_ADDRESS}/v1/webapi/automaticupgrades/channel/default/version | sed 's/v//')"
curl https://cdn.teleport.dev/install.sh | bash -s $TELEPORT_VERSION ${TELEPORT_EDITION}

echo ${TELEPORT_JOIN_TOKEN} > /tmp/token

# Start of teleport.yaml configuration
cat<<EOF >/etc/teleport.yaml
version: v3
teleport:
  auth_token: /tmp/token
  proxy_server: ${TELEPORT_ADDRESS}
  data_dir: /var/lib/teleport
  log:
    output: stderr
    severity: INFO
    format:
      output: text
ssh_service:
  enabled: true
  labels:
    env: dev
  commands: # https://goteleport.com/docs/admin-guides/management/admin/labels/
  - command:
    - getnodeinfo.sh
    name: stats
    period: 1m
proxy_service:
  enabled: false
auth_service:
  enabled: false
app_service:
  enabled: "yes"
  apps:
  - name: "nginx-app-dev"
    uri: tcp://localhost:80
    labels:
      env: dev
  - name: "nginx-app-prd"
    uri: tcp://localhost:80
    labels:
      env: prd
EOF

# Check for the existence of DATABASE_NAME, DATABASE_PROTOCOL, DATABASE_URI and append the db_service block if they exist
if [[ -n "${DATABASE_NAME}" && -n "${DATABASE_PROTOCOL}" && -n "${DATABASE_URI}" && -n "${DATABASE_SECRET_ID}" ]]; then
  DATABASE_HOST=$(echo "${DATABASE_URI}" | cut -d':' -f1)
  DATABASE_PORT=$(echo "${DATABASE_URI}" | cut -d':' -f2)

  # Fetch the secret JSON using AWS CLI
  DATABASE_SECRET_JSON=$(/usr/local/bin/aws secretsmanager get-secret-value --secret-id "${DATABASE_SECRET_ID}" --region "$REGION" --query SecretString --output text)
  export PGUSER=$(echo "$DATABASE_SECRET_JSON" | jq -r '.username')
  export PGPASSWORD=$(echo "$DATABASE_SECRET_JSON" | jq -r '.password')
  export PGSSLMODE="require"

  sudo amazon-linux-extras enable postgresql14
  sudo yum install -y postgresql

  # Run psql command with the exported variables
  psql --host="$DATABASE_HOST" --port="$DATABASE_PORT" --username="$PGUSER" --dbname="${DATABASE_NAME}" <<SQL
  GRANT rds_iam TO $PGUSER;
  CREATE USER "${DATABASE_TELEPORT_ADMIN_USER}" LOGIN CREATEROLE;
  GRANT rds_iam TO "${DATABASE_TELEPORT_ADMIN_USER}" WITH ADMIN OPTION;
  GRANT rds_superuser TO "${DATABASE_TELEPORT_ADMIN_USER}";
SQL

  cat<<EOF >>/etc/teleport.yaml
db_service:
  enabled: true
  databases:
  - name: "${DATABASE_NAME}-$RANDOM_SUFFIX"
    protocol: "${DATABASE_PROTOCOL}"
    uri: "${DATABASE_URI}"
    static_labels:
      env: dev
    dynamic_labels:
    - name: "status"
      command:
        - getavail.sh
        - $DATABASE_HOST
        - $DATABASE_PORT
        - ${DATABASE_PROTOCOL}
  - name: "${DATABASE_NAME}-prd"
    protocol: "${DATABASE_PROTOCOL}"
    uri: "${DATABASE_URI}"
    static_labels:
      env: prd
    dynamic_labels:
    - name: "status"
      command:
        - getavail.sh
        - $DATABASE_HOST
        - $DATABASE_PORT
        - ${DATABASE_PROTOCOL}
EOF
fi

# Check for the existence of DATABASE_NAME, DATABASE_PROTOCOL, DATABASE_URI and append the db_service block if they exist
if [[ -n "${DATABASE_TELEPORT_ADMIN_USER}" ]]; then
  cat<<EOF >>/etc/teleport.yaml
    admin_user:
      "name": "${DATABASE_TELEPORT_ADMIN_USER}"
EOF
fi

if [[ -n "${MONGO_DB_TELEPORT_DISPLAY_NAME}" && -n "${MONGO_DB_URI}" ]]; then
  cat <<EOF >> /etc/yum.repos.d/mongodb-org-8.0.repo
[mongodb-org-8.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/amazon/2023/mongodb-org/8.0/\$basearch/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-8.0.asc
EOF
  
sudo yum install -y mongodb-mongosh

cat <<EOF >>/etc/teleport.yaml
  - name: "${MONGO_DB_TELEPORT_DISPLAY_NAME}-dev"
    protocol: "mongodb"
    uri: "${MONGO_DB_URI}"
    static_labels:
      env: dev
    dynamic_labels:
    - name: "status"
      command:
        - getavail.sh
        - "${MONGO_DB_URI}"
        - 27017
        - mongodb
  - name: "${MONGO_DB_TELEPORT_DISPLAY_NAME}-prd"
    protocol: "mongodb"
    uri: "${MONGO_DB_URI}"
    static_labels:
      env: prd
    dynamic_labels:
    - name: "status"
      command:
        - getavail.sh
        - "${MONGO_DB_URI}"
        - 27017
        - mongodb
EOF
fi

systemctl enable teleport
systemctl start teleport
systemctl status teleport
rm -rf /tmp/info_lables