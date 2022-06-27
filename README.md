![Build](https://github.com/Invicton-Labs/terraform-local-file-data/actions/workflows/CICD.yml/badge.svg)

# Terraform Local File (Data)

On the Terraform Registry: [Invicton-Labs/file-data/local](https://registry.terraform.io/modules/Invicton-Labs/file-data/local/latest)

This module functions similarly to the [local_file](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) resource, but acts as a data source instead of a resource.

Specifically, if all input values are known at plan time, it will create the file during the plan step. If a file already exists with the same contents, it will not overwrite the file. It will also not update the file's last modified timestamp unless the relevant input variable is set.

This module also optionally supports "large" files. The [local_file](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) resource has a hard limit of 4MB; if you want to create files larger than 4MB, you can use the `max_characters` variable of this module to enable support for files with no size limits. Note, however, that Terraform will still run slowly when dealing with large files since it still stores the entire file content in the Terraform state.

This module has been tested on many flavors of Linux, Windows, and MacOS. If a system that you use is not included in the automated testing, open an issue to request addition of your preferred OS/shell.


## Limitations

- The `file_permission` and `directory_permission` variables have no effect when running on Windows, as PowerShell has no `chmod` equivalent.


## Usage

```
module "local-file-data" {
  source = "Invicton-Labs/file-data/local"

  filename = "${path.module}/testdir/test.txt"

  content = "Hello World!
}
```
