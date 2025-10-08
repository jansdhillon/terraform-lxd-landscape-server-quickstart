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
  default     = "noble"
  description = "Default alias of image. Can be overridden per instance. Takes precedence over fingerprint if both are specified."
}

variable "instance" {
  type = object({
    instance_name = string
    lxd_config    = optional(map(string))
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
    image_alias   = optional(string)
    instance_type = optional(string, "container")
    ppas          = optional(list(string))
    profiles      = optional(list(string))
    pro_token     = optional(string)
    remote        = optional(string, "ubuntu")
  })

  validation {
    condition     = contains(["virtual-machine", "container"], var.instance.instance_type)
    error_message = "valid values are: virtual-machine, container"
  }
}



variable "ppas" {
  type    = list(string)
  default = ["ppa:landscape/self-hosted-beta"]
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
  default     = "15m"
}

variable "smtp_host" {
  type    = string
  default = "smtp.sendgrid.net"
}

variable "smtp_port" {
  type    = number
  default = 587
}

variable "smtp_username" {
  type    = string
  default = "apikey"
}

variable "smtp_password" {
  type        = string
  default     = ""
  sensitive   = true
}

variable "fqdn" {
  type        = string
  default     = "landscape.example.com"
}

variable "domain" {
  type        = string
  default     = "example.com"
}
