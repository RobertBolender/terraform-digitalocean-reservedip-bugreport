variable "do_token" {}

provider "digitalocean" {
    token = var.do_token
}

resource "digitalocean_reserved_ip" "my_reserved_ip" {
    region = "sfo3"
}

resource "digitalocean_droplet" "my_droplet" {
  image = "ubuntu-22-04-x64"
  name = "my-droplet"
  region = "sfo3"
  size = "s-1vcpu-1gb"
}

resource "digitalocean_reserved_ip_assignment" "my_reserved_ip_assignment" {
    ip_address = digitalocean_reserved_ip.my_reserved_ip.ip_address
    droplet_id = digitalocean_droplet.my_droplet.id
}

resource "digitalocean_project" "my_project" {
    name = "my project"
    description = "my new project description"
    resources = [
        digitalocean_droplet.my_droplet.urn
    ]
}
