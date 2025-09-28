# terraform-lxd-landscape-server-quickstart

## Usage

```hcl
module "landscape_server_quickstart" {
  source  = "jansdhillon/landscape-server-quickstart/lxd"
 
  instance = {
    instance_name = "landscape-server"
    image_alias   = "jammy"
    ppa = "ppa:landscape/self-hosted-beta"
  }
}
```
