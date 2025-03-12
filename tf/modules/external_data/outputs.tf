output "my_external_ip" {
    value = jsondecode(data.http.external_ip.response_body).ip
}