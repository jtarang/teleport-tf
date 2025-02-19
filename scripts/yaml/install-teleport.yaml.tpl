#cloud-config
runcmd:
  - apt-get update -y
  - curl -fsSL "https://cdn.teleport.dev/install-v${TELEPORT_VERSION}.sh" | bash -s -- "${TELEPORT_VERSION}" "${TELEPORT_EDITION}"
