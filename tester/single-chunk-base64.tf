locals {
  single_chunk_base64_original_content = "hello world\ngoodbye world"
}

module "single_chunk_base64" {
  source           = "../"
  filename         = "${path.module}/../tmpfiles/single-chunk-base64.txt"
  content_base64   = base64encode(local.single_chunk_base64_original_content)
  unix_interpreter = var.unix_interpreter
}

locals {
  single_chunk_base64 = file(module.single_chunk_base64.complete ? module.single_chunk_base64.filename : module.single_chunk_base64.filename)
}

module "single_chunk_base64_no_change" {
  source = "../"
  depends_on = [
    module.single_chunk_base64
  ]
  filename         = module.single_chunk_base64.filename
  content_base64   = module.single_chunk_base64.content_base64
  unix_interpreter = var.unix_interpreter
}

module "check_single_chunk_base64" {
  source        = "Invicton-Labs/assertion/null"
  version       = "~>0.2.1"
  condition     = local.single_chunk_base64 == local.single_chunk_base64_original_content
  error_message = "single-chunk-base64: expected ${jsonencode(local.single_chunk_base64_original_content)}, got ${jsonencode(local.single_chunk_base64)}"
}

module "check_single_chunk_base64_no_change" {
  source  = "Invicton-Labs/assertion/null"
  version = "~>0.2.1"
  depends_on = [
    module.check_single_chunk_base64
  ]
  condition     = !module.single_chunk_base64_no_change.modified
  error_message = "single-chunk-base64-no-change: file required modification, which was unexpected."
}
