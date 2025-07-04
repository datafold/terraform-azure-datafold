# ┏━╸┏━┓┏┳┓┏┳┓┏━┓┏┓╻   ╻ ╻┏━┓┏━┓╻┏━┓┏┓ ╻  ┏━╸┏━┓
# ┃  ┃ ┃┃┃┃┃┃┃┃ ┃┃┗┫   ┃┏┛┣━┫┣┳┛┃┣━┫┣┻┓┃  ┣╸ ┗━┓
# ┗━╸┗━┛╹ ╹╹ ╹┗━┛╹ ╹   ┗┛ ╹ ╹╹┗╸╹╹ ╹┗━┛┗━╸┗━╸┗━┛

variable "deployment_name" {
  description = "The name of the deployment"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group where the resources will be created"
  type        = string
  default     = ""
}

variable "location" {
  description = "The Azure location where the resources will be created"
  type        = string
  default     = ""
}

variable "tags" {
  default     = {}
  type        = map(string)
  description = "Map of tags for resource"
}

# ╻  ┏━┓┏━┓╺┳┓   ┏┓ ┏━┓╻  ┏━┓┏┓╻┏━╸┏━╸┏━┓
# ┃  ┃ ┃┣━┫ ┃┃   ┣┻┓┣━┫┃  ┣━┫┃┗┫┃  ┣╸ ┣┳┛
# ┗━╸┗━┛╹ ╹╺┻┛   ┗━┛╹ ╹┗━╸╹ ╹╹ ╹┗━╸┗━╸╹┗╸

variable "app_gw_subnet" {
  type = object({ id = string })
}

variable "private_ip_address" {
  type        = string
  description = "The private IP address of the load balancer"
}

variable "ssl_cert_id" {
  type        = string
  description = "The ID of the SSL certificate to use for the load balancer"
}

variable "public_ip_id" {
  type    = string
}

variable "public_ip" {
  type    = string
}

variable "identity" {
  type = object({ id = string })
}

variable "domain_name" {
  type        = string
  description = "The domain name for the load balancer"
}

variable "ssl_cert_name" {
  description = "The name of the SSL certificate to use for the load balancer. This needs to be referenced by the k8s azure-application-gateway ingress config."
  type        = string
}

variable "lb_is_public" {
  description = "Flag that determines if LB is public"
  type        = bool
}
