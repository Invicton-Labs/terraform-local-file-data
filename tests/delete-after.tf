module "delete_after" {
  source           = "../"
  filename         = "${path.module}/../tmpfiles/delete-after.txt"
  content          = "hello world"
  unix_interpreter = var.unix_interpreter
  delete_after = [
    // This forces the delete to wait until the first check has occured
    module.check_delete_after_exists
  ]
}

module "check_delete_after_exists" {
  source  = "Invicton-Labs/assertion/null"
  version = "~>0.2.5"
  // The ternary forces a wait until the file has been created
  condition     = fileexists(module.delete_after.created ? module.delete_after.filename : null)
  error_message = "delete-after (exists): expected file to exist, but it does not"
}

module "check_delete_after_deleted" {
  source  = "Invicton-Labs/assertion/null"
  version = "~>0.2.5"
  depends_on = [
    // This forces a wait until the deletion has been completed as well
    module.delete_after
  ]
  condition     = !fileexists(module.delete_after.created ? module.delete_after.filename : null)
  error_message = "delete-after (deleted): expected file to be deleted, but it exists"
}
