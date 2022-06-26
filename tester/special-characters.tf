locals {
  special_characters_original_content = join("\r\n", [for i in range(20) : "`~!@#$%^&*()_+-=[]{};':\",./<>?\\"])
}

module "special_characters" {
  source           = "../"
  filename         = "${path.module}/../tmpfiles/special-characters.txt"
  content          = local.special_characters_original_content
  max_characters   = length(local.special_characters_original_content)
  chunk_size       = 76
  unix_interpreter = var.unix_interpreter
}

module "special_characters_no_change" {
  source = "../"
  depends_on = [
    module.special_characters
  ]
  filename         = module.special_characters.filename
  content          = module.special_characters.content
  max_characters   = module.special_characters.max_characters
  chunk_size       = module.special_characters.chunk_size
  unix_interpreter = var.unix_interpreter
}

locals {
  special_characters = file(module.special_characters.complete ? module.special_characters.filename : module.special_characters.filename)
}

module "check_special_characters" {
  source        = "Invicton-Labs/assertion/null"
  version       = "~>0.2.1"
  condition     = local.special_characters == module.special_characters.content
  error_message = "multi-chunk: expected ${jsonencode(module.special_characters.content)}, got ${jsonencode(local.special_characters)}"
}

module "check_special_characters_no_change" {
  source  = "Invicton-Labs/assertion/null"
  version = "~>0.2.1"
  depends_on = [
    module.check_special_characters
  ]
  condition     = !module.special_characters_no_change.modified
  error_message = "multi-chunk-no-change: file required modification, which was unexpected."
}
