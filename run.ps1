# Equivalent of set -e
$ErrorActionPreference = "Stop"

# Equivalent of set -u (https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/set-strictmode?view=powershell-7.1)
set-strictmode -version 3.0

$jsonpayload = [Console]::In.ReadLine()
$json = ConvertFrom-Json $jsonpayload
$_uuid = $json.id
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
    if ( $_idx -eq 0) {
        # It's the first chunk

        # Delete any leftover chunk files from a failed run
        Remove-Item "$_uuid.*"

        # Create the parent directories if necessary,
        # using the desired permissions.
        New-Item -ItemType Directory -Force -Path "$_directory" | Out-Null

        if ( $_append ) {
            # Append it to an existing file if desired
            # This is the only command that supports appending raw bytes. We use it because we have to, but it's slow.
            Add-Content "$_filename" -Value $([System.Convert]::FromBase64String($json.content)) -Encoding Byte -NoNewLine
        }
        else {
            # Otherwise, write without appending to overwrite any
            # existing files.
            [System.IO.File]::WriteAllBytes("$_filename", [System.Convert]::FromBase64String($json.content))
        }
    }
    else {
        # Determine the name of the previous chunk completion indicator file
        $_previous_chunk_filename = "$_uuid.$( $_idx - 1 )"
        
        # Wait for the file to be created
        while (!(Test-Path "$_previous_chunk_filename")) { Start-Sleep -Milliseconds 50 }
        
        # Delete the previous chunk's indicator file
        Remove-Item "$_previous_chunk_filename"

        # Once the previous chunk is done, append this chunk
        Add-Content "$_filename" -Value $([System.Convert]::FromBase64String($json.content)) -Encoding Byte -NoNewLine
    }
}

if ($_idx -ne ($_num_chunks - 1)) {
    New-Item -ItemType file "$_uuid.$_idx" | Out-Null
}

# We must return valid JSON in order for Terraform to not lose its mind
@{} | ConvertTo-Json
exit 0
