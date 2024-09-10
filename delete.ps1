# Equivalent of set -e
$ErrorActionPreference = "Stop"

# Equivalent of set -u (https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/set-strictmode?view=powershell-7.1)
set-strictmode -version 3.0

$jsonpayload = [Console]::In.ReadLine()
$json = ConvertFrom-Json $jsonpayload
$_filename = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($json.filename))

# -Force is required in case the file is 
# hidden or read-only
Remove-Item -Path "$_filename" -Force

# We must return valid JSON in order for Terraform to not lose its mind
@{} | ConvertTo-Json
exit 0
