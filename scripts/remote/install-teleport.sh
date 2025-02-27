#!/bin/bash
RANDOM_SUFFIX=$(openssl rand -base64 2 | tr -dc 'a-zA-Z0-9' | tr '[:upper:]' '[:lower:]')
sudo hostnamectl set-hostname "${EC2_INSTANCE_NAME}-$RANDOM_SUFFIX"
sudo bash -c "$(curl -fsSL https://nebula-dash-staging.cloud.gravitational.io/scripts/1562ccf7357e675b9cdb4df7897533b1/install-node.sh)"