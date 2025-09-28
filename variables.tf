variable "architecture" {
  type        = string
  default     = "x86_64"
  description = "CPU architecture"
}

variable "fingerprint" {
  type        = string
  default     = null
  description = "Default fingerprint of image. Can be overridden per instance."
}

variable "image_alias" {
  type        = string
  default     = null
  description = "Default alias of image. Can be overridden per instance. Takes precedence over fingerprint if both are specified."
}

variable "instance" {
  type = object({
    instance_name = string
    lxd_config   = optional(map(string))
    devices = optional(list(object({
      name       = string
      type       = string
      properties = map(string)
    })), [])
    execs = optional(list(object({
      name          = string
      command       = list(string)
      enabled       = optional(bool, true)
      trigger       = optional(string, "on_change")
      environment   = optional(map(string))
      working_dir   = optional(string)
      record_output = optional(bool, false)
      fail_on_error = optional(bool, false)
      uid           = optional(number, 0)
      gid           = optional(number, 0)
    })), [])
    files = optional(list(object({
      content            = optional(string)
      source_path        = optional(string)
      target_path        = string
      uid                = optional(number)
      gid                = optional(number)
      mode               = optional(string, "0755")
      create_directories = optional(bool, false)
    })), [])
    fingerprint   = optional(string)
    image_alias   = optional(string, "noble")
    instance_type = optional(string, "container")
    ppa           = optional(string, "ppa:landscape/self-hosted-beta")
    profiles      = optional(list(string))
    pro_token     = optional(string)
    remote        = optional(string, "ubuntu")
  })

  validation {
    condition = (
      (var.instance.fingerprint != null || var.instance.image_alias != null)
    )
    error_message = "Either var.instance.fingerprint or var.instance.image_alias must be set."
  }

  validation {
    condition = contains(["virtual-machine", "container"], var.instance.instance_type)
    error_message = "valid values are: virtual-machine, container"
  }
}



variable "ppa" {
  type    = string
  default = null
}

variable "pro_token" {
  type        = string
  description = "Ubuntu Pro token"
  sensitive   = true
  default     = null
  nullable    = true
}

variable "profiles" {
  type        = list(string)
  description = "Profiles to associate with all instances."
  default     = ["default"]
}

variable "registration_key" {
  type     = string
  nullable = true
  default  = null
}

variable "timeout" {
  type        = string
  description = "duration string to wait for instances to deploy"
  default     = "10m"
}
