module "landscape_server_quickstart" {
  source = "../../"

  instance = {
    instance_name = "disa-stig-compliant"
    image_alias   = "jammy"
    ppas          = var.ppas
  }
}
