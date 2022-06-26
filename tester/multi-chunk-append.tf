module "multi_chunk_append_1" {
  source           = "../"
  filename         = "${path.module}/../tmpfiles/multi-chunk-append.txt"
  content          = join("\n", [for i in range(20) : "hello world"])
  max_characters   = 260
  chunk_size       = 76
  append           = false
  unix_interpreter = var.unix_interpreter
}

module "multi_chunk_append_2" {
  source = "../"
  depends_on = [
    module.multi_chunk_append_1
  ]
  filename         = module.multi_chunk_append_1.filename
  content          = join("\n", [for i in range(20) : "goodbye world"])
  max_characters   = module.multi_chunk_append_1.max_characters
  chunk_size       = module.multi_chunk_append_1.chunk_size
  append           = true
  unix_interpreter = var.unix_interpreter
}

locals {
  multi_chunk_append_expected_combined = "${module.multi_chunk_append_1.content}${module.multi_chunk_append_2.content}"
  multi_chunk_append                   = file(module.multi_chunk_append_2.complete ? module.multi_chunk_append_2.filename : module.multi_chunk_append_2.filename)
}

module "multi_chunk_append_no_change" {
  source = "../"
  depends_on = [
    module.multi_chunk_append_2
  ]
  filename         = module.multi_chunk_append_2.filename
  content          = local.multi_chunk_append_expected_combined
  max_characters   = module.multi_chunk_append_1.max_characters + module.multi_chunk_append_2.max_characters
  chunk_size       = module.multi_chunk_append_2.chunk_size
  unix_interpreter = var.unix_interpreter
}

module "check_multi_chunk_append" {
  source        = "Invicton-Labs/assertion/null"
  version       = "~>0.2.1"
  condition     = local.multi_chunk_append == local.multi_chunk_append_expected_combined
  error_message = "multi-chunk-append: expected ${jsonencode(local.multi_chunk_append_expected_combined)}, got ${jsonencode(local.multi_chunk_append)}"
}

module "check_multi_chunk_append_no_change" {
  source  = "Invicton-Labs/assertion/null"
  version = "~>0.2.1"
  depends_on = [
    module.check_multi_chunk_append
  ]
  condition     = !module.multi_chunk_append_no_change.modified
  error_message = "multi-chunk-append-no-change: file required modification, which was unexpected."
}
