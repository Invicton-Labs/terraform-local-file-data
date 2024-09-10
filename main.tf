// Generate a UUID at plan-time
module "uuid" {
  source  = "Invicton-Labs/uuid/random"
  version = "~>0.2.0"
  // We only need a UUID if it's multi-chunk
  count = local.num_chunks > 1 ? 1 : 0
}

locals {
  is_windows = dirname("/") == "\\"

  // Whether the content came from the content_base64 variable
  is_base64 = var.content_base64 != null

  // Whether the output file already exists
  // Don't bother with this if we're appending, since we'll always need to modify in that case
  file_exists = var.append ? false : fileexists(var.filename)

  // Whether the file needs to be created/recreated. If it doesn't exist yet, that's true.
  needs_creation = !local.file_exists ? true : (
    // It does exist, so compare the existing file to the desired content
    local.is_base64 ? (
      // The content is base64, so compare the base64-encoded file content with the provided file content
      var.content_base64 != filebase64(var.filename)
      ) : (
      // The content is raw, so hash the content and compare that against the hash of the file
      base64sha256(var.content) != filebase64sha256(var.filename)
    )
  )

  // Calculate how many chunks we need to split it into
  num_chunks = var.max_characters == null ? 1 : ceil(var.max_characters / var.chunk_size)

  // Split it into chunks
  chunks = local.num_chunks == 1 ? {
    // If it needs creation, use the base64-encoded content (could be already b64, or we need to encode it ourselves)
    0 = local.needs_creation ? (local.is_base64 ? var.content_base64 : base64encode(var.content)) : ""
    } : {
    for i in range(0, local.num_chunks) :
    i => local.needs_creation ? (local.is_base64 ? substr(var.content_base64, i * var.chunk_size, var.chunk_size) : base64encode(substr(var.content, i * var.chunk_size, var.chunk_size))) : ""
  }

  // We only need a UUID if it's multi-chunk
  uuid = local.num_chunks > 1 ? module.uuid[0].uuid : ""

  query = {
    create               = local.needs_creation ? "true" : "false"
    touch                = var.force_update_last_modified ? "true" : "false"
    uuid                 = local.uuid
    filename             = base64encode(abspath(var.filename))
    file_permission      = var.file_permission
    directory_permission = var.directory_permission
    directory            = base64encode(dirname(abspath(var.filename)))
    append               = var.append ? "true" : "false"
    num_chunks           = local.num_chunks
  }
}

module "assert_at_least_one_chunk" {
  source        = "Invicton-Labs/assertion/null"
  version       = "~>0.2.5"
  condition     = local.num_chunks > 0
  error_message = "Num chunks: ${local.num_chunks}"
}

data "external" "create_file_chunk" {
  depends_on = [
    module.assert_at_least_one_chunk,
    local.file_exists
  ]
  program  = local.is_windows ? ["powershell.exe", "${abspath(path.module)}/create.ps1"] : [var.unix_interpreter, "${abspath(path.module)}/create.sh"]
  for_each = local.chunks
  // If it's Windows, just use the input value since PowerShell can natively handle JSON decoding
  query = (
    local.is_windows ?
    merge(local.query, {
      idx     = tonumber(each.key)
      content = each.value
    }) :
    {
      // If it's Unix, we have to convert all characters that JSON escapes into special strings that we can easily convert back WITHOUT needing any other installed tools such as jq
      "" = join("|", [
        "",
        local.query.create,
        local.query.touch,
        local.query.uuid,
        local.query.filename,
        local.query.file_permission,
        local.query.directory_permission,
        local.query.directory,
        local.query.append,
        local.query.num_chunks,
        tonumber(each.key),
        each.value,
        "",
      ])
    }
  )
  // Force the data source to wait for the apply, if that is what is desired
  working_dir = (jsonencode(var.dynamic_depends_on) == "" ? true : true) && ((var.force_wait_for_apply ? uuid() : "") == "") ? "${path.module}/tmpfiles" : "${path.module}/tmpfiles"
}

data "external" "delete_file" {
  depends_on = [
    data.external.create_file_chunk,
  ]
  program = local.is_windows ? ["powershell.exe", "${abspath(path.module)}/delete.ps1"] : [var.unix_interpreter, "${abspath(path.module)}/delete.sh"]
  count   = length(var.delete_after) > 0 ? 1 : 0
  // If it's Windows, just use the input value since PowerShell can natively handle JSON decoding
  query = (local.is_windows ?
    merge(
      local.query,
      {
        filename = local.query.filename
      }
    ) :
    {
      // If it's Unix, we have to convert all characters that JSON escapes into special strings that we can easily convert back WITHOUT needing any other installed tools such as jq
      "" = join("|", [
        "",
        local.query.filename,
        "",
      ])
  })
  // Force the data source to wait for all dependencies to be done
  working_dir = jsonencode(var.delete_after) == "" ? "${path.module}/tmpfiles" : "${path.module}/tmpfiles"
}
