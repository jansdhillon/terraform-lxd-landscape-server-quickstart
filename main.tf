resource "lxd_cached_image" "image_name" {
  source_image  = var.instance.fingerprint != null ? var.instance.fingerprint : var.instance.image_alias
  source_remote = var.instance.remote

  lifecycle {
    ignore_changes = [aliases]
  }
}

resource "lxd_instance" "instance" {
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
    for_each = var.instance.files != null ? var.instance.files : []
    content {
      content            = file.value.content
      source_path        = file.value.source_path
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
      "000-install-prereqs" = {
        command = [
          "/bin/bash", "-c",
          "apt-get update && apt-get install -y ca-certificates software-properties-common"
        ]
        trigger       = "once"
        record_output = true
        fail_on_error = true
      },
      "001-add-ppa" = {
        command = [
          "/bin/bash", "-c",
          "add-apt-repository -y ${coalesce(var.instance.ppa, var.ppa)}"
        ]
        trigger       = "once"
        record_output = true
        fail_on_error = true
        enabled       = length(compact([var.instance.ppa, var.ppa])) > 0
      },
      "002-install-landscape-server-quickstart" = {
        command = [
          "/bin/bash", "-c",
          "DEBIAN_FRONTEND=noninteractive apt-get install -y landscape-server-quickstart"
        ]
        trigger       = "once"
        record_output = true
        fail_on_error = true
      },
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
