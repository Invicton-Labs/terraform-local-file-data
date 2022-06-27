locals {
  multi_chunk_base64_external_original_content = filebase64("${path.module}/random-bytes")
}

module "multi_chunk_base64_external" {
  source           = "../"
  filename         = "${path.module}/../tmpfiles/multi-chunk-base64-external.txt"
  content_base64   = local.multi_chunk_base64_external_original_content
  max_characters   = length(local.multi_chunk_base64_external_original_content)
  chunk_size       = 76
  unix_interpreter = var.unix_interpreter
}

module "multi_chunk_base64_external_no_change" {
  source = "../"
  depends_on = [
    module.multi_chunk_base64_external
  ]
  filename         = module.multi_chunk_base64_external.filename
  content_base64   = module.multi_chunk_base64_external.content_base64
  max_characters   = module.multi_chunk_base64_external.max_characters
  chunk_size       = module.multi_chunk_base64_external.chunk_size
  unix_interpreter = var.unix_interpreter
}

locals {
  multi_chunk_base64_external = filebase64(module.multi_chunk_base64_external.complete ? module.multi_chunk_base64_external.filename : module.multi_chunk_base64_external.filename)
}

module "check_multi_chunk_base64_external" {
  source        = "Invicton-Labs/assertion/null"
  version       = "~>0.2.1"
  condition     = local.multi_chunk_base64_external == local.multi_chunk_base64_external_original_content
  error_message = "multi-chunk-base64-external: final contents do not match expected contents"
}

module "check_multi_chunk_base64_external_no_change" {
  source  = "Invicton-Labs/assertion/null"
  version = "~>0.2.1"
  depends_on = [
    module.check_multi_chunk_base64_external
  ]
  condition     = !module.multi_chunk_base64_external_no_change.modified
  error_message = "multi-chunk-base64-external-no-change: file required modification, which was unexpected."
}
