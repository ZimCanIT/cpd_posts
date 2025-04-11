data "http" "my_public_ip" {
  url      = "https://api.ipify.org"
  insecure = false
}