output "my_external_ip" {
    value = trimspace(data.http.external_ip.response_body)
}