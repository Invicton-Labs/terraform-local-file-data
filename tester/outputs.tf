// This causes all assertions to be checked in all cases
output "done" {
  value = length([
    module.check_multi_chunk_append.checked,
    module.check_multi_chunk_append_no_change.checked,
    module.check_multi_chunk_base64.checked,
    module.check_multi_chunk_base64_no_change.checked,
    module.check_multi_chunk.checked,
    module.check_multi_chunk_no_change.checked,
    module.check_single_append.checked,
    module.check_single_chunk_append_no_change.checked,
    module.check_single_chunk_base64.checked,
    module.check_single_chunk_base64_no_change.checked,
    module.check_single_chunk.checked,
    module.check_single_chunk_no_change.checked,
    module.check_special_characters.checked,
    module.check_special_characters_no_change.checked,
    module.check_touch.checked,
    module.check_multi_chunk_base64_external.checked,
    module.check_multi_chunk_base64_external_no_change.checked,
  ]) == 0 ? true : true
}
