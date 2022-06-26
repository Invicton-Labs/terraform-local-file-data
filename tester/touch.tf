module "touch_1" {
  source           = "../"
  filename         = "${path.module}/../tmpfiles/touch.txt"
  content          = "hello world"
  append           = false
  unix_interpreter = var.unix_interpreter
}

module "touch_2" {
  source = "../"
  depends_on = [
    module.touch_1
  ]
  filename                   = module.touch_1.filename
  content                    = module.touch_1.content
  force_update_last_modified = true
  unix_interpreter           = var.unix_interpreter
}

locals {
  touch = file(module.touch_2.complete ? module.touch_2.filename : module.touch_2.filename)
}

module "check_touch" {
  source        = "Invicton-Labs/assertion/null"
  version       = "~>0.2.1"
  condition     = local.touch == "${module.touch_2.content}"
  error_message = "touch: expected ${jsonencode(module.touch_2.content)}, got ${jsonencode(local.touch)}"
}
