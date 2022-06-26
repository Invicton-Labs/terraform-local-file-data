module "permissions" {
  source               = "../"
  filename             = "${path.module}/../tmpfiles/subdir/permissions.txt"
  content              = "hello world"
  file_permission      = "0770"
  directory_permission = "0770"
  unix_interpreter     = var.unix_interpreter
}

locals {
  permissions = file(module.permissions.complete ? module.permissions.filename : module.permissions.filename)
}

module "check_permissions" {
  source        = "Invicton-Labs/assertion/null"
  version       = "~>0.2.1"
  condition     = local.permissions == module.permissions.content
  error_message = "permissions: expected ${jsonencode(module.permissions.content)}\", got ${jsonencode(local.permissions)}"
}
