#!/bin/bash

set +x

SESSION_TOKEN=$(curl -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" -X PUT "http://169.254.169.254/latest/api/token")
INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $SESSION_TOKEN" -s http://169.254.169.254/latest/meta-data/instance-id)
REGION=$(curl -H "X-aws-ec2-metadata-token: $SESSION_TOKEN" -s http://169.254.169.254/latest/meta-data/placement/region)

DATABASE_HOST=$(echo "${DATABASE_URI}" | cut -d':' -f1)
DATABASE_PORT=$(echo "${DATABASE_URI}" | cut -d':' -f2)
TELEPORT_DATABASE_DISPLAY_NAME=$(echo "${DATABASE_URI}" | cut -d'.' -f1 | sed 's/'"${TELEPORT_DISPLAY_NAME_STRIP_STRING}"'//g')

install_dependencies() {
    sudo yum -y update
    sudo yum -y install git nmap jq
}

setup_info_labels() {
    git clone https://github.com/jtarang/teleportinfolabels.git /tmp/info_labels
    cd /tmp/info_labels && sudo chmod +x *.sh 
    cd /tmp/info_labels && sudo cp -rv *.sh /usr/local/bin/
}

setup_nginx() {
    sudo amazon-linux-extras install nginx1.12
    sudo systemctl start nginx
    sudo systemctl enable nginx
    sudo systemctl status nginx
}

update_aws_cli() {
    sudo yum -y remove awscli
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update
}

configure_aws_instance() {
    /usr/local/bin/aws ec2 delete-tags --resources $INSTANCE_ID --tags Key="teleport.dev/creator"
    /usr/local/bin/aws ec2 create-tags --resources $INSTANCE_ID --tags Key=InstanceID,Value=$INSTANCE_ID
    /usr/local/bin/aws ec2 modify-instance-metadata-options --instance-id $INSTANCE_ID --http-endpoint enabled --instance-metadata-tags enabled --region $REGION
}

set_hostname() {
    sudo hostnamectl set-hostname "$(echo "${EC2_INSTANCE_NAME}" | sed 's/'"${TELEPORT_DISPLAY_NAME_STRIP_STRING}"'//g')"
}

install_teleport() {
    TELEPORT_VERSION="$(curl https://${TELEPORT_ADDRESS}/v1/webapi/automaticupgrades/channel/default/version | sed 's/v//')"
    curl https://cdn.teleport.dev/install.sh | bash -s $TELEPORT_VERSION ${TELEPORT_EDITION}
    echo ${TELEPORT_JOIN_TOKEN} > /tmp/token
}

configure_teleport_yaml() {
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
    env: ${ENVIRONMENT_TAG}
  commands:
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
  - name: "${ENVIRONMENT_TAG}-nginx-app"
    uri: tcp://localhost:80
    labels:
      env: ${ENVIRONMENT_TAG}
EOF
}

configure_postgresql_service() {
    sudo amazon-linux-extras enable postgresql14
    sudo yum install -y postgresql
}

setup_postgresql_db() {
    # Fetch the secret JSON using AWS CLI
    DATABASE_SECRET_JSON=$(/usr/local/bin/aws secretsmanager get-secret-value --secret-id "${DATABASE_SECRET_ID}" --region "$REGION" --query SecretString --output text)
    export PGUSER=$(echo "$DATABASE_SECRET_JSON" | jq -r '.username')
    export PGPASSWORD=$(echo "$DATABASE_SECRET_JSON" | jq -r '.password')
    export PGSSLMODE="require"

    psql --host="$DATABASE_HOST" --port="$DATABASE_PORT" --username="$PGUSER" --dbname="${DATABASE_NAME}" <<SQL
    CREATE DATABASE teleport_int_db;
    CREATE DATABASE teleport_qa_db;
    CREATE DATABASE teleport_dev_db;
    CREATE DATABASE teleport_stg_db;
    CREATE DATABASE teleport_prd_db;
    GRANT rds_iam TO $PGUSER;
    CREATE USER "${DATABASE_TELEPORT_ADMIN_USER}" LOGIN CREATEROLE;
    GRANT rds_iam TO "${DATABASE_TELEPORT_ADMIN_USER}" WITH ADMIN OPTION;
    GRANT rds_superuser TO "${DATABASE_TELEPORT_ADMIN_USER}";
SQL
}

configure_postgresql_service_block() {
    cat<<EOF >>/etc/teleport.yaml
db_service:
  enabled: true
  databases:
  - name: "${ENVIRONMENT_TAG}-$TELEPORT_DATABASE_DISPLAY_NAME"
    protocol: "${DATABASE_PROTOCOL}"
    uri: "${DATABASE_URI}"
    static_labels:
      env: ${ENVIRONMENT_TAG}
    dynamic_labels:
    - name: "status"
      command:
        - getavail.sh
        - $DATABASE_HOST
        - $DATABASE_PORT
        - ${DATABASE_PROTOCOL}
EOF
}

configure_admin_user() {
    if [[ -n "${DATABASE_TELEPORT_ADMIN_USER}" ]]; then
        cat<<EOF >>/etc/teleport.yaml
    admin_user:
      "name": "${DATABASE_TELEPORT_ADMIN_USER}"
EOF
    fi
}

setup_mongodb_service() {
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
  - name: "${ENVIRONMENT_TAG}-${MONGO_DB_TELEPORT_DISPLAY_NAME}"
    protocol: "mongodb"
    uri: "${MONGO_DB_URI}"
    static_labels:
      env: ${ENVIRONMENT_TAG}
    dynamic_labels:
    - name: "status"
      command:
        - getavail.sh
        - "${MONGO_DB_URI}"
        - 27017
        - mongodb
EOF
    fi
}

install_dependencies
setup_info_labels
setup_nginx
update_aws_cli
configure_aws_instance
set_hostname
install_teleport
configure_teleport_yaml

if [[ -n "${DATABASE_NAME}" && -n "${DATABASE_PROTOCOL}" && -n "${DATABASE_URI}" && -n "${DATABASE_SECRET_ID}" ]]; then
    configure_postgresql_service
    setup_postgresql_db
    configure_postgresql_service_block
fi

#configure_admin_user
setup_mongodb_service

systemctl enable teleport
systemctl start teleport
systemctl status teleport
rm -rf /tmp/info_labels