output "filename" {
  depends_on = [
    data.external.create_file
  ]
  description = "The path to the file that was created. Does not return until the file has been created."
  value       = var.filename
}

output "complete" {
  depends_on = [
    data.external.create_file
  ]
  description = "Always `true`, but does not return until the file has been created."
  value       = true
}

output "num_chunks" {
  description = "The number of chunks that the file was split into during the writing process (this output is only useful for debugging)."
  value       = local.num_chunks
}
