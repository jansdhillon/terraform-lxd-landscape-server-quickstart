resource "lxd_cached_image" "image_name" {
  source_image  = coalesce(var.instance.fingerprint, var.instance.image_alias, var.fingerprint, var.image_alias)
  source_remote = var.instance.remote

  lifecycle {
    ignore_changes = [aliases]
  }
}

locals {
  postfix_main_cf = <<-EOT
    myhostname = ${var.fqdn}
    mydomain = ${var.domain}
    myorigin = ${var.domain}
    masquerade_domains = ${var.domain}
    mydestination = localhost
    default_transport = smtp
    relay_transport = smtp
    relayhost = [${var.smtp_host}]:${var.smtp_port}
    smtp_sasl_auth_enable = yes
    smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
    smtp_sasl_security_options = noanonymous
    header_size_limit = 4096000
    smtp_use_tls = yes
    smtp_tls_security_level = encrypt
    smtp_sasl_tls_security_options = noanonymous
  EOT

  postfix_sasl_passwd = <<-EOT
    [${var.smtp_host}]:${var.smtp_port} ${var.smtp_username}:${var.smtp_password}
  EOT

  postfix_files = [
    {
      target_path        = "/etc/postfix/main.cf"
      content            = local.postfix_main_cf
      uid                = 0
      gid                = 0
      mode               = "0644"
      create_directories = true
    },
    {
      target_path        = "/etc/postfix/sasl_passwd"
      content            = local.postfix_sasl_passwd
      uid                = 0
      gid                = 0
      mode               = "0600"
      create_directories = true
    }
  ]
}

resource "lxd_instance" "landscape" {
  name = var.instance.instance_name

  image = lxd_cached_image.image_name.fingerprint

  profiles = compact(coalesce(var.instance.profiles, var.profiles))

  type = var.instance.instance_type

  config = var.instance.lxd_config != null ? var.instance.lxd_config : {}


  dynamic "device" {
    for_each = var.instance.devices != null ? var.instance.devices : []
    content {
      name       = device.value.name
      type       = device.value.type
      properties = device.value.properties
    }
  }

  dynamic "file" {
    for_each = concat(var.instance.files != null ? var.instance.files : [], local.postfix_files)
    content {
      content            = try(file.value.content, null)
      source_path        = try(file.value.source_path, null)
      target_path        = file.value.target_path
      uid                = file.value.uid
      gid                = file.value.gid
      mode               = file.value.mode
      create_directories = file.value.create_directories
    }
  }

  timeouts = {
    create = var.timeout
  }

  execs = merge(
    {
      "0000-install-prereqs" = {
        command = [
          "/bin/bash", "-c",
          "apt-get update && apt-get install -y ca-certificates software-properties-common"
        ]
        trigger       = "once"
        record_output = true
        fail_on_error = true
      },
      "0001-add-ppas" = {
        command = [
          "/bin/bash", "-c",
          join(" && ", [
            for ppa in coalesce(var.instance.ppas, var.ppas) :
            "add-apt-repository -y ${ppa}"
          ])
        ]
        record_output = true
        fail_on_error = true
      },
      "0002-install-postfix" = {
        command = [
          "/bin/bash", "-c",
          "export DEBIAN_FRONTEND=noninteractive && apt-get update && apt-get install -y postfix && postmap /etc/postfix/sasl_passwd && chmod 600 /etc/postfix/sasl_passwd.db && rm /etc/postfix/sasl_passwd && /etc/init.d/postfix restart"
        ]
        record_output = true
        fail_on_error = true
      },
      "0003-install-quickstart" = {
        command = [
          "/bin/bash", "-c",
          "export DEBIAN_FRONTEND=noninteractive; apt-get update && apt-get install -y landscape-server-quickstart"
        ]
        record_output = true
        fail_on_error = true
      }

    },
    {
      for exec in(var.instance.execs != null ? var.instance.execs : []) : exec.name => {
        command       = exec.command
        enabled       = exec.enabled
        trigger       = exec.trigger
        environment   = exec.environment
        working_dir   = exec.working_dir
        record_output = exec.record_output
        fail_on_error = exec.fail_on_error
        uid           = exec.uid
        gid           = exec.gid
      }
    }
  )
}
