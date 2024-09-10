# Equivalent of set -e
$ErrorActionPreference = "Stop"

# Equivalent of set -u (https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/set-strictmode?view=powershell-7.1)
set-strictmode -version 3.0

$jsonpayload = [Console]::In.ReadLine()
$json = ConvertFrom-Json $jsonpayload
$_uuid = $json.uuid
$_idx = [System.Convert]::ToInt32($json.idx)

$_filename = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($json.filename))
$_create = [System.Convert]::ToBoolean($json.create)
$_touch = [System.Convert]::ToBoolean($json.touch)

# If the "create" variable is false, don't actually create the file, just do special actions here
if ( -not $_create ) {
    # If we're not creating the file, but still need to update the timestamp on it, do that without writing content
    # Only if this is the first chunk though
    if ( ( $_idx -eq 0 ) -and $_touch ) {
        (Get-Item "$_filename").LastWriteTime = (Get-Date)
    }
    # Exit out without doing anything else
    @{} | ConvertTo-Json
    exit 0
}

$_directory = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($json.directory))
$_append = [System.Convert]::ToBoolean($json.append)
$_num_chunks = [System.Convert]::ToInt32($json.num_chunks)

if ($_num_chunks -eq 1) {
    # There's only one chunk, so just write directly to the destination file
    # First, create the directory if necessary
    New-Item -ItemType Directory -Force -Path "$_directory" | Out-Null
    # Store the content in the file
    if ( $_append ) {
        # This is the only command that supports appending raw bytes. We use it because we have to, but it's slow.
        Add-Content "$_filename" -Value $([System.Convert]::FromBase64String($json.content)) -Encoding Byte -NoNewLine
    }
    else {
        [System.IO.File]::WriteAllBytes("$_filename", [System.Convert]::FromBase64String($json.content))
    }
}
else {
    if ( $_idx -eq ($_num_chunks - 1)) {
        # It's the last chunk

        # Create the parent directories if necessary
        New-Item -ItemType Directory -Force -Path "$_directory" | Out-Null

        if ((-not $_append) -and (Test-Path $_filename)) {
            Remove-Item "$_filename" | Out-Null
        }

        # Loop through all previous chunks
        for ($_chunk_idx = 0; $_chunk_idx -lt ($_num_chunks - 1); $_chunk_idx += 1 ) {

            # Determine the name of the previous chunk file
            $_chunk_filename = "$_uuid.$_chunk_idx"

            # Wait for the file to be created
            while (!(Test-Path "$_chunk_filename")) { Start-Sleep -Milliseconds 50 }

            # Read the base64 content from file, decode it, and append the bytes to the final target file.
            # This is the only command that supports appending raw bytes. We use it because we have to, but it's slow.
            Add-Content "$_filename" -Value $([System.Convert]::FromBase64String([System.IO.File]::ReadAllText("$_chunk_filename"))) -Encoding Byte -NoNewLine
        }

        # Append the final chunk
        Add-Content "$_filename" -Value $([System.Convert]::FromBase64String($json.content)) -Encoding Byte -NoNewLine

        # Remove all chunk files
        Remove-Item "$_uuid.*"
    }
    else {
        # Determine the name of the chunk file
        $_chunk_filename = "$_uuid.$_idx"
        
        # Write the content to the chunk file (still in base64 format)
        [System.IO.File]::WriteAllText("$_chunk_filename", $json.content)
    }
}

# We must return valid JSON in order for Terraform to not lose its mind
@{} | ConvertTo-Json
exit 0
