locals {
  multi_chunk_base64_original_content = join("\n", [for i in range(20) : "hello world"])
}

module "multi_chunk_base64" {
  source           = "../"
  filename         = "${path.module}/../tmpfiles/multi-chunk-base64.txt"
  content_base64   = base64encode(local.multi_chunk_base64_original_content)
  max_characters   = length(base64encode(local.multi_chunk_base64_original_content))
  chunk_size       = 76
  unix_interpreter = var.unix_interpreter
}

module "multi_chunk_base64_no_change" {
  source = "../"
  depends_on = [
    module.multi_chunk_base64
  ]
  filename         = module.multi_chunk_base64.filename
  content_base64   = module.multi_chunk_base64.content_base64
  max_characters   = module.multi_chunk_base64.max_characters
  chunk_size       = module.multi_chunk_base64.chunk_size
  unix_interpreter = var.unix_interpreter
}

locals {
  multi_chunk_base64 = file(module.multi_chunk_base64.complete ? module.multi_chunk_base64.filename : module.multi_chunk_base64.filename)
}

module "check_multi_chunk_base64" {
  source        = "Invicton-Labs/assertion/null"
  version       = "~>0.2.1"
  condition     = local.multi_chunk_base64 == local.multi_chunk_base64_original_content
  error_message = "multi-chunk-base64: expected ${jsonencode(local.multi_chunk_base64_original_content)}, got ${jsonencode(local.multi_chunk_base64)}"
}

module "check_multi_chunk_base64_no_change" {
  source  = "Invicton-Labs/assertion/null"
  version = "~>0.2.1"
  depends_on = [
    module.check_multi_chunk_base64
  ]
  condition     = !module.multi_chunk_base64_no_change.modified
  error_message = "multi-chunk-base64-no-change: file required modification, which was unexpected."
}
