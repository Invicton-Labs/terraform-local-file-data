set -e
if ! [ -z "$BASH" ]; then
    # Only Bash supports this feature
    set -o pipefail
fi
set -u

# This checks if we're running on MacOS
_kernel_name="$(uname -s)"
case "${_kernel_name}" in
    darwin*|Darwin*)    
        # It's MacOS.
        # Mac doesn't support the "-d" flag for base64 decoding, 
        # so we have to use the full "--decode" flag instead.
        _decode_flag="--decode" ;;
    *)
        # It's NOT MacOS.
        # Not all Linux base64 installs (e.g. BusyBox) support the full
        # "--decode" flag. So, we use "-d" here, since it's supported
        # by everything except MacOS.
        _decode_flag="-d" ;;
esac

# This checks if the "-n" flag is supported on this shell, and sets vars accordingly
if [ "`echo -n`" = "-n" ]; then
  _echo_n=""
  _echo_c="\c"
else
  _echo_n="-n"
  _echo_c=""
fi

_raw_input="$(cat)"

# We know that all of the inputs are base64-encoded, and "|" is not a valid base64 character, so therefore it
# cannot possibly be included in the stdin.
IFS="|"
set -o noglob
set -- $_raw_input""
_create="$2"
_touch="$3"
_uuid="$4"
_filename="$(echo "$5" | base64 $_decode_flag)"
_file_permissions="$6"
_directory_permissions="$7"
_directory="$(echo "$8" | base64 $_decode_flag)"
_append="$9"
_num_chunks="${10}"
_idx="${11}"
# ${12} is the content itself, which we reference directly down below

# If the "create" variable is false, don't actually create the file, just do special actions here
if [ "$_create" != "true" ]; then
    # If we're not creating the file, but still need to update the timestamp on it, do that without writing content
    # Only if this is the first chunk though
    if [ $_idx -eq 0 ]; then
        if [ "$_touch" = "true" ]; then
            touch "$_filename"
        fi
        # Set permissions on the file
        chmod $_file_permissions "$_filename"
    fi
    # Exit out without doing anything else
    echo $_echo_n "{}${_echo_c}"
    exit 0
fi

if [ $_num_chunks -eq 1 ]; then
    # Create the parent directories if necessary
    mkdir -p -m "$_directory_permissions" "$_directory"

    # There's only one chunk, so just write directly to the destination file
    # Store the content in the file
    if [ "$_append" = "true" ]; then
        echo "${12}" | base64 $_decode_flag >> "$_filename"
    else
        echo "${12}" | base64 $_decode_flag > "$_filename"
    fi
    # Set the file permissions on the file. We do this at the end in case 
    # the permissions preclude this process from appending more content.
    chmod "$_file_permissions" "$_filename"
else
    # Check if it's the last chunk
    if [ $_idx -eq $(( $_num_chunks - 1 )) ]; then
        # It's the last chunk

        # Delete any leftover chunk files from a failed run
        # The -f prevents an error if there are no matching files
        rm -f "$_uuid.*"

        # Create the parent directories if necessary,
        # using the desired permissions.
        mkdir -p -m "$_directory_permissions" "$_directory"

        if [ "$_append" = "true" ]; then
            # Append it to an existing file if desired
            echo "${12}" | base64 $_decode_flag >> "$_filename"
        else
            # Otherwise, write without appending to overwrite any
            # existing files.
            echo "${12}" | base64 $_decode_flag > "$_filename"
        fi
        
        _chunk_idx=0
        while [ $_chunk_idx -le  ]; do
            _chunk_filename="$_uuid.$_chunk_idx"

            # Wait for the chunk to be complete
            while [ ! -f "$_chunk_filename" ]; do sleep 0.05; done


            true > "$j.json"
            _chunk_idx=$(( $_chunk_idx + 1 ))
        done

        # Set permissions on the file. Wedo this at the end in case the 
        # permissions preclude this process from appending more content.
        chmod "$_file_permissions" "$_filename"

    else
        # Determine the name of the chunk file
        _chunk_filename="$_uuid.$_idx"
        
        # Write the content to the chunk file
        echo "${12}" | base64 $_decode_flag > "$_chunk_filename"
    fi
fi

# We must return valid JSON in order for Terraform to not lose its mind
echo $_echo_n "{}${_echo_c}"
exit 0