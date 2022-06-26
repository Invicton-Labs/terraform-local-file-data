module "single_chunk_append_1" {
  source           = "../"
  filename         = "${path.module}/../tmpfiles/single-chunk-append.txt"
  content          = "hello world"
  append           = false
  unix_interpreter = var.unix_interpreter
}

module "single_chunk_append_2" {
  source = "../"
  depends_on = [
    module.single_chunk_append_1
  ]
  filename         = module.single_chunk_append_1.filename
  content          = "goodbye world"
  append           = true
  unix_interpreter = var.unix_interpreter
}

locals {
  single_chunk_append_expected_combined = "${module.single_chunk_append_1.content}${module.single_chunk_append_2.content}"
  single_chunk_append                   = file(module.single_chunk_append_2.complete ? module.single_chunk_append_2.filename : module.single_chunk_append_2.filename)
}

module "single_chunk_append_no_change" {
  source = "../"
  depends_on = [
    module.single_chunk_append_2
  ]
  filename         = module.single_chunk_append_2.filename
  content          = local.single_chunk_append_expected_combined
  unix_interpreter = var.unix_interpreter
}

module "check_single_append" {
  source        = "Invicton-Labs/assertion/null"
  version       = "~>0.2.1"
  condition     = local.single_chunk_append == local.single_chunk_append_expected_combined
  error_message = "single-chunk-append: expected ${jsonencode(local.single_chunk_append_expected_combined)}, got ${jsonencode(local.single_chunk_append)}"
}

module "check_single_chunk_append_no_change" {
  source  = "Invicton-Labs/assertion/null"
  version = "~>0.2.1"
  depends_on = [
    module.check_single_append
  ]
  condition     = !module.single_chunk_append_no_change.modified
  error_message = "single-chunk-append-no-change: file required modification, which was unexpected."
}
