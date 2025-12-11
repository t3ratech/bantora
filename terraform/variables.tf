variable "project_id" {
  description = "The Google Cloud Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "db_user" {
  description = "Database User"
  type        = string
  default     = "bantora"
}

variable "db_password" {
  description = "Database Password"
  type        = string
  sensitive   = true
}

variable "jwt_secret" {
  description = "JWT Secret Key"
  type        = string
  sensitive   = true
}

variable "gemini_api_key" {
  description = "Gemini API Key"
  type        = string
  sensitive   = true
}

variable "image_tag" {
  description = "Docker Image Tag"
  type        = string
  default     = "latest"
}

variable "bantora_ai_gemini_url" {
  description = "Gemini API URL"
  type        = string
  default     = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent"
}
