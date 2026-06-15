variable "status_check_token" {
  type        = string
  default     = ""
  description = <<-EOT
    Token the Datafold server uses to authorize its /livez and /readyz
    health-check probes. Leave empty to have a random token generated and
    wired into the deployment automatically; set it to pin a specific value.
  EOT
}
