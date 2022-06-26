module "multi_chunk" {
  source           = "../"
  filename         = "${path.module}/../tmpfiles/multi-chunk.txt"
  content          = join(", ", [for i in range(20) : "hello world"])
  max_characters   = 260
  chunk_size       = 76
  unix_interpreter = var.unix_interpreter
}

module "multi_chunk_no_change" {
  source = "../"
  depends_on = [
    module.multi_chunk
  ]
  filename         = module.multi_chunk.filename
  content          = module.multi_chunk.content
  max_characters   = module.multi_chunk.max_characters
  chunk_size       = module.multi_chunk.chunk_size
  unix_interpreter = var.unix_interpreter
}

locals {
  multi_chunk = file(module.multi_chunk.complete ? module.multi_chunk.filename : module.multi_chunk.filename)
}

module "check_multi_chunk" {
  source        = "Invicton-Labs/assertion/null"
  version       = "~>0.2.1"
  condition     = local.multi_chunk == module.multi_chunk.content
  error_message = "multi-chunk: expected ${jsonencode(module.multi_chunk.content)}, got ${jsonencode(local.multi_chunk)}"
}

module "check_multi_chunk_no_change" {
  source  = "Invicton-Labs/assertion/null"
  version = "~>0.2.1"
  depends_on = [
    module.check_multi_chunk
  ]
  condition     = !module.multi_chunk_no_change.modified
  error_message = "multi-chunk-no-change: file required modification, which was unexpected."
}
