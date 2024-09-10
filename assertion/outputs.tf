output "error_message" {
  description = "The value of the `error_message` input variable."
  value       = var.error_message
}

output "condition" {
  description = "The value of the `condition` input variable."
  value       = var.condition
}

# data "cloudinit_config" "check" {
#   part {
#     content = var.condition
#   }
# }

output "checked" {
  description = "Whether the condition has passed validation (used for assertion dependencies)."
  # value       = data.cloudinit_config.check.rendered == "" ? true : true
  value = var.condition == true ? true : true
}
