data "http" "external_ip" {
  url = "https://api.ipify.org?format=json"
}