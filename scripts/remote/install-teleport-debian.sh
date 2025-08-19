#!/bin/bash

set +x

SESSION_TOKEN=$(curl -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" -X PUT "http://169.254.169.254/latest/api/token")
INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $SESSION_TOKEN" -s http://169.254.169.254/latest/meta-data/instance-id)
REGION=$(curl -H "X-aws-ec2-metadata-token: $SESSION_TOKEN" -s http://169.254.169.254/latest/meta-data/placement/region)

DATABASE_HOST=$(echo "${DATABASE_URI}" | cut -d':' -f1)
DATABASE_PORT=$(echo "${DATABASE_URI}" | cut -d':' -f2)
TELEPORT_DATABASE_DISPLAY_NAME=$(echo "${DATABASE_URI}" | cut -d'.' -f1 | sed 's/'"${TELEPORT_DISPLAY_NAME_STRIP_STRING}"'//g')

install_dependencies() {
    # Update package lists
    sudo apt update

    # Install required packages
    sudo apt install -y git nmap jq docker.io unzip curl ca-certificates gnupg lsb-release locales-all

    # Start and enable Docker
    sudo systemctl start docker
    sudo systemctl enable docker

    sudo apt install -y docker-compose
}

setup_info_labels() {
    git clone https://github.com/jtarang/teleportinfolabels.git /tmp/info_labels
    cd /tmp/info_labels && sudo chmod +x *.sh 
    cd /tmp/info_labels && sudo cp -rv *.sh /usr/local/bin/
}

setup_nginx() {
    sudo apt install -y nginx
    sudo systemctl start nginx
    sudo systemctl enable nginx
    sudo systemctl status nginx
}

update_aws_cli() {
    # Remove old AWS CLI if it exists
    sudo apt remove -y awscli || true
    
    # Install AWS CLI v2
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update
    
    # Clean up
    rm -rf awscliv2.zip aws/
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
  mcp_demo_server: true
  apps:
  - name: "${ENVIRONMENT_TAG}-nginx-app"
    uri: tcp://localhost:80
    labels:
      env: ${ENVIRONMENT_TAG}
  - name: "${ENVIRONMENT_TAG}-grafana"
    uri: http://localhost:3000
    public_addr: ${ENVIRONMENT_TAG}-grafana.nebula-dash.teleport.sh
    rewrite:
        headers:
        - "Host: ${ENVIRONMENT_TAG}-grafana.nebula-dash.teleport.sh"
        - "Origin: https://${ENVIRONMENT_TAG}-grafana.nebula-dash.teleport.sh"
    labels:
      env: ${ENVIRONMENT_TAG}
tracing_service:
  enabled: true
  exporter_url: grpc://127.0.0.1:4317
  sampling_rate_per_million: 1000000
EOF
}

configure_postgresql_service() {
    # Install PostgreSQL client
    sudo apt update
    sudo apt install -y postgresql-client
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
    if [[ -n "${DATABASE_TELEPORT_ADMIN_USER}" && "${ENVIRONMENT_TAG}" == "prd" ]]; then
        cat<<EOF >>/etc/teleport.yaml
    admin_user:
      "name": "${DATABASE_TELEPORT_ADMIN_USER}"
EOF
    fi
}

setup_mongodb_service() {
    if [[ -n "${MONGO_DB_TELEPORT_DISPLAY_NAME}" && -n "${MONGO_DB_URI}" ]]; then
        # Install MongoDB GPG key and repository for Debian
        curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | sudo gpg --dearmor -o /usr/share/keyrings/mongodb-server-8.0.gpg
        
        # Add MongoDB repository
        echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/debian $(lsb_release -cs)/mongodb-org/8.0 main" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list
        
        # Update and install mongosh
        sudo apt update
        sudo apt install -y mongodb-mongosh

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

setup_grafana_service() {
    mkdir -p ~/grafana/
    sudo tee ~/grafana/docker-compose.yaml > /dev/null << EOF
services:
  grafana:
    image: grafana/grafana
    ports:
      - "3000:3000"
    restart: always
    environment:
      - GF_SERVER_HTTP_PORT=3000
      - GF_SERVER_PROTOCOL=http
      - GF_SERVER_ENABLE_GZIP=true
      - GF_SERVER_ROOT_URL=https://${ENVIRONMENT_TAG}-grafana.nebula-dash.teleport.sh
      - GF_SECURITY_ALLOW_EMBEDDING=true
      #- GF_SECURITY_ADMIN_USER=jasmit.tarang@goteleport.sh
      - GF_USERS_DEFAULT_THEME=dark
      - GF_AUTH_BASIC_ENABLED=false
      - GF_AUTH_JWT_ENABLED=true
      - GF_AUTH_JWT_HEADER_NAME=Teleport-Jwt-Assertion
      - GF_AUTH_JWT_EMAIL_CLAIM=sub
      - GF_AUTH_JWT_USERNAME_CLAIM=sub
      - GF_AUTH_JWT_JWK_SET_URL=https://nebula-dash.teleport.sh:443/.well-known/jwks.json
      - GF_AUTH_JWT_AUTO_SIGN_UP=true
      - GF_AUTH_JWT_USERNAME_ATTRIBUTE_PATH=username
      - GF_AUTH_JWT_ROLE_ATTRIBUTE_PATH=contains(roles[*], 'access') && 'Admin' || contains(roles[*], 'editor') && 'Editor' || 'Viewer'
      - GF_AUTH_JWT_ALLOW_ASSIGN_GRAFANA_ADMIN=true
EOF
    docker-compose -f ~/grafana/docker-compose.yaml up -d
}

# Main execution
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
setup_grafana_service

systemctl enable teleport
systemctl start teleport
systemctl status teleport
rm -rf /tmp/info_labels