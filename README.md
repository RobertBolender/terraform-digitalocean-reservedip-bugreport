# DigitalOcean Terraform ReservedIP Bug Report

This repo provides a minimal Terraform configuration in order to demonstrate a few surprises (possibly bugs?) in the DigitalOcean API.

This was tested with `registry.terraform.io/digitalocean/digitalocean` version `2.30.0`.

## How to use this repo

- Check out the resource definitions in `main.tf`
- Create a file named `terraform.tfvars` and populate it with a DigitalOcean API key, using the `terraform.tfvars.example` file as a template
- Run `terraform plan -out tfplan` and `terraform apply "tfplan"`

## Description of Errors

1. A `digitalocean_reserved_ip` resource assigned to a droplet is exposed to the `digitalocean_project` as if it was a Floating IP.

Relevant steps to reproduce:

- Create a droplet
- Create a project, listing the droplet as a resource
- Create a reserved IP
- Create a reserved IP assignment for the droplet ID

After running `terraform apply` the first time, a subsequent run of `terraform plan` will show that the "floatingip" resource would be staged for removal. A reserved IP attached to a droplet in a project also gets assigned to the project, but I do not have the reserved IP listed as a project resource in the project resource definition.

```
Terraform will perform the following actions:

  # digitalocean_project.my_project will be updated in-place
  ~ resource "digitalocean_project" "my_project" {
        id          = [REDACTED]
        name        = "my project"
      ~ resources   = [
          - "do:floatingip:[REDACTED]",
            # (1 unchanged element hidden)
        ]
        # (7 unchanged attributes hidden)
    }

Plan: 0 to add, 1 to change, 0 to destroy.
```

2. A `digitalocean_reserved_ip` cannot be assigned as a `digitalocean_project` resource

If I attempt to add `digitalocean_reserved_ip.my_reserved_ip.urn` to the `digitalocean_project.my_project` `resources` array with a fresh start (all prior resources destroyed with `terraform destroy`), I get this error when running `terraform apply`:

```
Error: Error creating project: Error assigning resources: POST https://api.digitalocean.com/v2/projects/[REDACTED]/resources: 400 (request "3f3ae541-8d29-4ef6-8a2c-b1de6fea6450") resource types must be one of the following: AppPlatformApp Bucket Database Domain DomainRecord Droplet Firewall FloatingIp Image Kubernetes LoadBalancer MarketplaceApp Saas Volume
```

Note that `FloatingIp` is allowed but `ReservedIp` is not.

3. A `digitalocean_reserved_ip` cannot be added to an existing `digitalocean_project` as a resource

Attempting to add `digitalocean_reserved_ip.my_reserved_ip.urn` to the `resources` array after running the first `terraform apply` shows this output for `terraform plan`:

```
Terraform will perform the following actions:

  # digitalocean_project.my_project will be updated in-place
  ~ resource "digitalocean_project" "my_project" {
        id          = [REDACTED]
        name        = "my project"
      ~ resources   = [
          - "do:floatingip:[REDACTED]",
          + "do:reservedip:[REDACTED]",
            # (1 unchanged element hidden)
        ]
        # (7 unchanged attributes hidden)
    }

Plan: 0 to add, 1 to change, 0 to destroy.
```

But throws this error when running `terraform apply`:

```
Error: Error assigning resources to default project: Error assigning resources: POST https://api.digitalocean.com/v2/projects/[REDACTED]/resources: 412 (request "18d0f2ff-dd19-4954-a240-008ed04bd895") Cannot move a Reserved IP with an associated Droplet. Move the Droplet instead
```

## Workarounds

1. It is possible to manually enter the IP address for the floating IP with a literal string in the `digitalocean_project` `resources` array, such as `do:floatingip:12.345.67.89`

2. It is possible to use the deprecated `digitalocean_floating_ip` and `digitalocean_floating_ip_assignment` resources instead of the newer `digitalocean_reserved_ip` and `digitalocean_reserved_ip_assignment resources`.
