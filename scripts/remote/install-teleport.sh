#!/bin/bash

# Get Info Label Scripts
sudo yum -y install git nmap
git clone https://github.com/stevenGravy/teleportinfolabels.git /tmp/info_lables
cd /tmp/info_lables && sudo chmod +x *.sh 
cd /tmp/info_lables && sudo cp -rv *.sh /usr/local/bin/

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
  commands: # https://goteleport.com/docs/admin-guides/management/diagnostics/
  - command:
    - getnodeinfo.sh
    name: stats
    period: 1m
proxy_service:
  enabled: false
auth_service:
  enabled: false
EOF

# Check for the existence of DATABASE_NAME, DATABASE_PROTOCOL, DATABASE_URI and append the db_service block if they exist
if [[ -n "${DATABASE_NAME}" && -n "${DATABASE_PROTOCOL}" && -n "${DATABASE_URI}" ]]; then
  DATABASE_HOST=$(echo "${DATABASE_URI}" | cut -d':' -f1)
  DATABASE_PORT=$(echo "${DATABASE_URI}" | cut -d':' -f2) 
  cat<<EOF >>/etc/teleport.yaml
db_service:
  enabled: true
  databases:
  - name: "${DATABASE_NAME}"
    protocol: "${DATABASE_PROTOCOL}"
    uri: "${DATABASE_URI}"
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

systemctl enable teleport
systemctl start teleport
systemctl status teleport
rm -rf /tmp/info_lables