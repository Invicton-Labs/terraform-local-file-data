variable "dynamic_depends_on" {
  description = "Has the same functionality as the built-in `depends_on` field, but allows specifying any type of value."
  type        = any
  default     = null
  nullable    = true
}

variable "filename" {
  description = "The path of the file to create."
  type        = string
  nullable    = false
}

variable "content" {
  description = "The content of the file to create. Conflicts with `content_base64`."
  type        = string
  default     = null
  nullable    = true
  validation {
    condition     = var.content != null ? var.content_base64 == null : true
    error_message = "If the `content` variable is not null, the `content_base64` variable must be null."
  }
  validation {
    condition     = var.content == null ? var.content_base64 != null : true
    error_message = "If the `content` variable is null, the `content_base64` variable must not be null."
  }
}

variable "content_base64" {
  description = "The base64 encoded content of the file to create. Use this when dealing with binary data. Conflicts with `content`."
  type        = string
  default     = null
  nullable    = true
  validation {
    condition     = var.content_base64 == null ? true : length(regexall("^[a-zA-Z0-9/+=]*$", var.content_base64)) == 1
    error_message = "The `content_base64` input variable must contain only valid base64 characters ([a-zA-Z0-9/+=])."
  }
}

variable "file_permission" {
  description = "The permission to set for the created file. Expects a 4-character string (e.g. \"0777\"). Only has an effect when running on Unix-based systems. If this value is modified, the permissions of the file will also be modified, even if it already exists."
  type        = string
  default     = "0777"
  nullable    = false
  validation {
    condition     = length(regexall("^[0-9]{3,4}$", var.file_permission)) == 1
    error_message = "The `file_permission` input variable must be a string containing 3 or 4 digits and no other characters."
  }
}

variable "directory_permission" {
  description = "The permission to set for any directories created. Expects a 4-character string (e.g. \"0777\"). Only has an effect when running on Unix-based systems, and only if the directory does not already exist."
  type        = string
  default     = "0777"
  nullable    = false
  validation {
    condition     = length(regexall("^[0-9]{3,4}$", var.directory_permission)) == 1
    error_message = "The `directory_permission` input variable must be a string containing 3 or 4 digits and no other characters."
  }
}

variable "force_wait_for_apply" {
  description = "Whether to force this module to wait for apply-time to execute the shell command. Otherwise, it will run during plan-time if possible (i.e. if all inputs are known during plan time)."
  type        = bool
  default     = false
  nullable    = false
}

variable "append" {
  description = "Whether to append to the file instead of overwriting it. CAUTION: this will append to the file on each plan (or apply, if `force_wait_for_apply` is set to `true), so the file may grow VERY LARGE."
  type        = bool
  default     = false
  nullable    = false
}

variable "max_characters" {
  description = <<EOF
The maximum number of characters that the file will contain. This is only to be used when the size of the file exceeds 4MB, which is the maximum size that various Terraform plugins can support.

If this value is set, this module will split the file contents into pieces that are smaller than the limit and only send one chunk at a time. If this value is not set, it will assume that the file is smaller than the 4MB limit.
EOF
  type        = number
  default     = null
  nullable    = true
}

variable "force_update_last_modified" {
  description = "By default, this module will not do anything if there is already a local file with contents that match the input variable contents. If this variable is set to `true`, the existing file's `last modified` timestamp will be updated to the current time, even if the file itself doesn't need to be modified."
  type        = bool
  default     = false
  nullable    = false
}

variable "chunk_size" {
  description = "Set this variable to override the default per-file chunk size. This is generally only used for development and testing and should not normally be used. If you do set it, ensure that you set it to a value that is a multiple of 76 so that it doesn't break base64 encoding where it splits."
  type        = number
  // We're limited to 4MB, which is about 3,000,000 bytes before the 36% base64 overhead.
  // With Terraform's UTF-8 encoding, there could be up to 4 bytes per character, so 3,000,000/4 = 749,968 characters max.
  // To be able to handle base64 encoding and not break it when splitting, we use the nearest multiple of 76, since the
  // base64 specs use line lengths of 76 characters
  default  = 749968
  nullable = false
  validation {
    condition     = var.chunk_size % 76 == 0
    error_message = "The `chunk_size` value must be a multiple of 76."
  }
  validation {
    condition     = (var.max_characters == null ? 1 : ceil(var.max_characters / var.chunk_size)) <= 1024
    error_message = "The given file would require ${var.max_characters == null ? 1 : ceil(var.max_characters / var.chunk_size)} chunk operations, which is more than the limit of 1024."
  }
  validation {
    condition     = length(var.content != null ? var.content : var.content_base64) <= var.chunk_size || var.max_characters != null
    error_message = "If the content length is greater than the file chunk size (${var.chunk_size} characters), then the `max_characters` variable must be provided and known during the plan step."
  }
}

variable "unix_interpreter" {
  description = "The interpreter to use when running commands on a Unix-based system. This is primarily used for testing, and should usually be left to the default value."
  type        = string
  default     = "/bin/sh"
  nullable    = false
}

variable "delete_after" {
  description = <<EOF
  If this value is set and not empty, then the file will be deleted after all of the provided items have been applied (in the same manner as `depends_on`)."

  This is useful if you need to write out a temporary file that is used by other shell scripts, such as credential files.
EOF
  type        = list(any)
  default     = []
  nullable    = false
}
