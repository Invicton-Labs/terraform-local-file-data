output "error_message" {
  description = "The value of the `error_message` input variable."
  value       = var.error_message
}

output "condition" {
  description = "The value of the `condition` input variable."
  value       = var.condition
}

resource "terraform_data" "assertion" {
  input = var.condition
}
output "checked" {
  description = "Whether the condition has passed validation (used for assertion dependencies)."
  value       = terraform_data.assertion.output != "" ? true : false
}
