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

variable "bantora_sms_provider" {
  description = "SMS provider"
  type        = string
}

variable "bantora_sms_account_sid" {
  description = "SMS account SID"
  type        = string
  sensitive   = true
}

variable "bantora_sms_auth_token" {
  description = "SMS auth token"
  type        = string
  sensitive   = true
}

variable "bantora_sms_from_number" {
  description = "SMS from number"
  type        = string
}

variable "bantora_sms_verification_code_length" {
  description = "SMS verification code length"
  type        = number
}

variable "bantora_sms_verification_code_expiry_minutes" {
  description = "SMS verification code expiry minutes"
  type        = number
}

variable "bantora_sms_max_attempts" {
  description = "SMS max verification attempts"
  type        = number
}
