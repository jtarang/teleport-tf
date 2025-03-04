#!/bin/bash
RANDOM_SUFFIX=$(openssl rand -base64 2 | tr -dc 'a-zA-Z0-9' | tr '[:upper:]' '[:lower:]')
sudo hostnamectl set-hostname "${EC2_INSTANCE_NAME}-$RANDOM_SUFFIX"

TELEPORT_VERSION="$(curl https://${TELEPORT_ADDRESS}/v1/webapi/automaticupgrades/channel/default/version | sed 's/v//')"
curl https://goteleport.com/static/install.sh | bash -s $TELEPORT_VERSION ${TELEPORT_EDITION}

echo ${TELEPORT_JOIN_TOKEN} > /tmp/token

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
    os: amazon-linux
  commands: # https://goteleport.com/docs/admin-guides/management/diagnostics/
    - name: "load_average"
      command: ["/bin/sh", "-c", "cut -d' ' -f1 /proc/loadavg"]
      period: "30s"
    - name: "disk_used"
      command: ["/bin/sh", "-c", "df -hTP / | awk '{print \$6}' | egrep '^[0-9][0-9]'"]
      period: "2m0s"
proxy_service:
  enabled: false
auth_service:
  enabled: false
EOF

systemctl enable teleport
systemctl start teleport
systemctl status teleport

