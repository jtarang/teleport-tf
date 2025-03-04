output "teleport_join_token" {
    value = teleport_provision_token.teleport_join_token.metadata.name
}