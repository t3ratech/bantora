output "bantora_web_url" {
  description = "URL of the Bantora Web Service"
  value       = google_cloud_run_v2_service.bantora_web.uri
}

output "bantora_api_url" {
  description = "URL of the Bantora API Service"
  value       = google_cloud_run_v2_service.bantora_api.uri
}
