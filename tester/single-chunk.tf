module "single_chunk" {
  source           = "../"
  filename         = "${path.module}/../tmpfiles/single-chunk.txt"
  content          = "hello world"
  unix_interpreter = var.unix_interpreter
}

locals {
  single_chunk = file(module.single_chunk.complete ? module.single_chunk.filename : module.single_chunk.filename)
}

module "single_chunk_no_change" {
  source = "../"
  depends_on = [
    module.single_chunk
  ]
  filename         = module.single_chunk.filename
  content          = module.single_chunk.content
  unix_interpreter = var.unix_interpreter
}

module "check_single_chunk" {
  source        = "Invicton-Labs/assertion/null"
  version       = "~>0.2.1"
  condition     = local.single_chunk == module.single_chunk.content
  error_message = "single-chunk: expected ${jsonencode(module.single_chunk.content)}, got ${jsonencode(local.single_chunk)}"
}

module "check_single_chunk_no_change" {
  source  = "Invicton-Labs/assertion/null"
  version = "~>0.2.1"
  depends_on = [
    module.check_single_chunk
  ]
  condition     = !module.single_chunk_no_change.modified
  error_message = "single-chunk-no-change: file required modification, which was unexpected."
}
