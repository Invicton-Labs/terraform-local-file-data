// Check that the correct content inputs are provided
module "assert_valid_input" {
  source  = "Invicton-Labs/assertion/null"
  version = "~>0.2.1"
  condition = length([for c in [
    local.var_content,
    local.var_content_base64
    ] :
    true
    if c != null
  ]) == 1
  error_message = "Exactly one of `content` or `content_base64` must be provided."
}

// Check that the file is within the single-chunk size limits unless the user has made it clear that
// they want it to be multi-chunk.
module "assert_chunked" {
  source        = "Invicton-Labs/assertion/null"
  version       = "~>0.2.1"
  condition     = length(local.is_base64 ? local.var_content_base64 : local.var_content) <= local.var_chunk_size || local.var_max_characters != null
  error_message = "If the content length is greater than the file chunk size (${local.var_chunk_size} characters), then the `max_characters` variable must be provided and known during the plan step."
}

// Ensure there aren't too many chunks
module "assert_num_chunks" {
  source        = "Invicton-Labs/assertion/null"
  version       = "~>0.2.1"
  condition     = local.num_chunks <= 1024
  error_message = "The given file would require ${local.num_chunks} chunk operations, which is more than the limit of 1024."
}

locals {
  is_windows = dirname("/") == "\\"

  // Whether the content came from the content_base64 variable
  is_base64 = local.var_content_base64 != null

  // Find the correct content source
  //content = module.assert_valid_input.checked ? (local.is_base64 ? local.var_content_base64 : local.var_content) : null

  // Whether the output file already exists
  // Don't bother with this if we're appending, since we'll always need to modify in that case
  file_exists = module.assert_valid_input.checked ? fileexists(local.var_filename) && !local.var_append : null

  // Whether the file needs to be created/recreated. If it doesn't exist yet, that's true.
  needs_creation = !local.file_exists ? true : (
    // It does exist, so compare the existing file to the desired content
    local.is_base64 ? (
      // The content is base64, so compare the base64-encoded file content with the provided file content
      local.var_content_base64 != filebase64(local.var_filename)
      ) : (
      // The content is raw, so hash the content and compare that against the hash of the file
      base64sha256(local.var_content) != filebase64sha256(local.var_filename)
    )
  )

  /*
  // Try decoding the content if it's base64
  content_decoded = local.file_exists && local.is_base64 ? try(base64decode(local.content), null) : null

  // Ensure that the content we're reviewing is the "most raw" we can get it
  // Only compute this if the file already exists and we need to compare content, to save memory if not
  content_raw = local.file_exists ? (local.content_decoded == null ? local.content : local.content_decoded) : null

  // Get the length of the content
  // Only compute this if the file already exists and we need to compare content, to save memory if not
  content_raw_length = local.file_exists ? length(local.content_raw) : null

  // The full content except for the last character
  // Only compute this if the file already exists and we need to compare content, to save memory if not
  content_raw_except_last = local.file_exists ? (local.content_raw_length == 0 ? "" : substr(local.content_raw, 0, local.content_raw_length - 1)) : null

  // The various hashes that we'll accept as "equal" to the existing file
  possible_hashes = local.file_exists ? concat(
    [
      // The hash of the full content is OK
      base64sha256(local.content)
    ],
    // Terraform does weird things with CRLF, see https://github.com/hashicorp/terraform/issues/30619
    // So, if the final character is a CRLF, CR, or LF, we allow matching on different line endings
    // for this ONE CHARACTER, it's the only one that's allowed to be slightly different.
    local.content_raw_length > 0 && contains(["\r\n", "\r", "\n"], substr(local.content_raw, -1, -1)) ? [
      // If we decoded the base64 to get the raw content, then re-encode it before taking the hash
      base64sha256(local.content_decoded == null ? join("", [local.content_raw_except_last, "\r"]) : base64encode(join("", [local.content_raw_except_last, "\r"]))),
      base64sha256(local.content_decoded == null ? join("", [local.content_raw_except_last, "\n"]) : base64encode(join("", [local.content_raw_except_last, "\n"]))),
    ] : []
  ) : null

  // If the input is base64, then we want to compare against the base64-encoded file for apples-to-apples comparison
  file_hash = local.file_exists ? (local.is_base64 ? base64sha256(filebase64(local.var_filename)) : filebase64sha256(local.var_filename)) : null

  // Whether or not the file needs to be created. Could be that it was never created before, or
  // that it has been deleted, or that the content has changed.
  needs_creation = local.file_exists ? !contains(local.possible_hashes, local.file_hash) : true
*/

  // Calculate how many chunks we need to split it into
  num_chunks = local.var_max_characters == null ? 1 : ceil(local.var_max_characters / local.var_chunk_size)

  // Split it into chunks
  chunks = local.num_chunks == 1 ? {
    // If it needs creation, use the base64-encoded content (could be already b64, or we need to encode it ourselves)
    0 = local.needs_creation ? (local.is_base64 ? local.var_content_base64 : base64encode(local.var_content)) : ""
    } : {
    for i in module.assert_num_chunks.checked ? range(0, local.num_chunks) : null :
    i => local.needs_creation ? (local.is_base64 ? substr(local.var_content_base64, i * local.var_chunk_size, local.var_chunk_size) : base64encode(substr(local.var_content, i * local.var_chunk_size, local.var_chunk_size))) : ""
  }

  // Create a unique ID, which we generate from the absolute path of the file, plus some other parameters that will
  // hopefully make it unique. It SHOULD be unique because this module should never be used twice with exactly the
  // same filename, as they would conflict anyways. We can't use the `uuid` function, because that function doesn't
  // return a value until apply time.
  id = sha256(jsonencode([
    local.needs_creation,
    local.var_force_wait_for_apply,
    local.var_force_update_last_modified,
    abspath(local.var_filename),
    local.is_base64,
    local.var_file_permission,
    local.var_directory_permission,
    local.var_append,
    local.num_chunks,
    terraform.workspace,
    abspath(path.module),
    base64sha256(local.is_base64 ? local.var_content_base64 : local.var_content),
  ]))

  query = {
    create               = local.needs_creation ? "true" : "false"
    touch                = local.var_force_update_last_modified ? "true" : "false"
    id                   = local.id
    filename             = base64encode(abspath(local.var_filename))
    file_permission      = local.var_file_permission
    directory_permission = local.var_directory_permission
    directory            = base64encode(dirname(abspath(local.var_filename)))
    append               = local.var_append ? "true" : "false"
    num_chunks           = local.num_chunks
  }
}

data "external" "create_file_chunk" {
  depends_on = [
    local.file_exists
  ]
  program  = local.is_windows ? ["powershell.exe", "${abspath(path.module)}/run.ps1"] : [local.var_unix_interpreter, "${abspath(path.module)}/run.sh"]
  for_each = local.chunks
  // If it's Windows, just use the input value since PowerShell can natively handle JSON decoding
  query = (local.is_windows ? merge(local.query, {
    idx     = tonumber(each.key)
    content = each.value
    }) : {
    // If it's Unix, we have to convert all characters that JSON escapes into special strings that we can easily convert back WITHOUT needing any other installed tools such as jq
    "" = join("|", [
      "",
      local.query.create,
      local.query.touch,
      local.query.id,
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
  })
  // Force the data source to wait for the apply, if that is what is desired
  working_dir = module.assert_chunked.checked && (jsonencode(local.var_dynamic_depends_on) == "" ? true : true) && ((local.var_force_wait_for_apply ? uuid() : "") == "") ? "${path.module}/tmpfiles" : "${path.module}/tmpfiles"
}
