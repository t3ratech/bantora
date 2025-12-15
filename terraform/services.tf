# Bantora API Service
resource "google_cloud_run_v2_service" "bantora_api" {
  name     = "bantora-api"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/bantora-repo/bantora-api:${var.image_tag}"
      ports {
        container_port = 3081
      }
      resources {
        limits = {
          cpu    = "1000m"
          memory = "1024Mi"
        }
      }
      env {
        name = "SPRING_PROFILES_ACTIVE"
        value = "prod"
      }
      env {
        name  = "SPRING_CLOUD_GCP_SQL_INSTANCE_CONNECTION_NAME"
        value = google_sql_database_instance.bantora_db.connection_name
      }
      env {
        name  = "SPRING_CLOUD_GCP_SQL_DATABASE_NAME"
        value = google_sql_database.database.name
      }
      env {
        name  = "SPRING_DATASOURCE_USERNAME"
        value = var.db_user
      }
      env {
        name  = "SPRING_DATASOURCE_PASSWORD"
        value = var.db_password
      }
      env {
        name  = "API_INTERNAL_PORT" 
        value = "3081"
      }
      env {
        name = "SERVER_PORT" # Cloud Run expects this or PORT env, Spring Boot uses server.port
        value = "3081"
      }
      
      env {
        name  = "DB_HOST"
        value = google_sql_database_instance.bantora_db.private_ip_address
      }
      env {
        name  = "DB_PORT"
        value = "3432" 
      }
      env {
        name  = "DB_INTERNAL_PORT"
        value = "3432"
      }
      env {
        name  = "DB_NAME"
        value = google_sql_database.database.name
      }
      env {
        name  = "DB_USERNAME"
        value = var.db_user
      }
      env {
        name  = "DB_PASSWORD"
        value = var.db_password
      }

      # Redis (Memorystore)
      env {
        name  = "REDIS_HOST"
        value = google_redis_instance.bantora_redis.host
      }
      env {
        name  = "REDIS_PORT"
        value = google_redis_instance.bantora_redis.port
      }
      env {
        name  = "BANTORA_LOG_DEST"
        value = "/var/log/bantora"
      }
      env {
        name  = "REDIS_INTERNAL_PORT"
        value = "3379"
      }
      # Redis Auth is disabled by default on Basic Tier without auth_enabled=true
      env {
        name  = "REDIS_PASSWORD"
        value = "" 
      }

      # JWT Config
      env {
        name  = "JWT_SECRET"
        value = var.jwt_secret
      }
      env {
        name = "BANTORA_JWT_SECRET" 
        value = var.jwt_secret
      }
      env {
        name = "BANTORA_JWT_ACCESS_TOKEN_EXPIRATION_MS"
        value = "900000"
      }
      env {
        name = "BANTORA_JWT_REFRESH_TOKEN_EXPIRATION_MS"
        value = "604800000"
      }
      env {
        name = "BANTORA_JWT_ISSUER"
        value = "bantora-api"
      }
      env {
        name = "BANTORA_JWT_AUDIENCE"
        value = "bantora-users"
      }

      # Argon2id
      env {
        name = "BANTORA_ARGON2_ITERATIONS"
        value = "3"
      }
      env {
        name = "BANTORA_ARGON2_MEMORY"
        value = "65536"
      }
      env {
        name = "BANTORA_ARGON2_PARALLELISM"
        value = "4"
      }
      env {
        name = "BANTORA_ARGON2_SALT_LENGTH"
        value = "32"
      }
      env {
        name = "BANTORA_ARGON2_HASH_LENGTH"
        value = "64"
      }

      env {
        name = "BANTORA_ALLOWED_ORIGINS"
        value = google_cloud_run_v2_service.bantora_web.uri
      }
      env {
        name = "TZ"
        value = "Africa/Johannesburg"
      }
      
      # Rate Limiting
      env {
        name = "BANTORA_RATE_LIMIT_ENABLED"
        value = "true"
      }
      env {
        name = "BANTORA_RATE_LIMIT_REQUESTS_PER_MINUTE"
        value = "100"
      }
      env {
        name = "BANTORA_RATE_LIMIT_BURST_CAPACITY"
        value = "150"
      }

      # Multi-language
      env {
        name = "BANTORA_DEFAULT_LOCALE"
        value = "en"
      }
      env {
        name = "BANTORA_SUPPORTED_LOCALES"
        value = "en,sw,yo,zu,am,ar,fr,pt,ha,ig,so,af,sn"
      }

      # Polls
      env {
        name = "BANTORA_POLL_MIN_OPTIONS"
        value = "2"
      }
      env {
        name = "BANTORA_POLL_MAX_OPTIONS"
        value = "10"
      }
      env {
        name = "BANTORA_POLL_MIN_DURATION_HOURS"
        value = "24"
      }
      env {
        name = "BANTORA_POLL_MAX_DURATION_DAYS"
        value = "90"
      }
      env {
        name = "BANTORA_POLL_APPROVAL_REQUIRED"
        value = "true"
      }
      env {
        name = "BANTORA_POLL_AI_MODERATION_ENABLED"
        value = "false"
      }
      
      # SMS (Dummy values for now or sourced if needed)
      env {
        name = "BANTORA_SMS_PROVIDER"
        value = "twilio"
      }
       env {
        name = "BANTORA_SMS_ACCOUNT_SID"
        value = "dummy"
      }
       env {
        name = "BANTORA_SMS_AUTH_TOKEN"
        value = "dummy"
      }
       env {
        name = "BANTORA_SMS_FROM_NUMBER"
        value = "+263771234567"
      }
      env {
        name = "BANTORA_SMS_VERIFICATION_CODE_LENGTH"
        value = "6"
      }
      env {
        name = "BANTORA_SMS_VERIFICATION_CODE_EXPIRY_MINUTES"
        value = "10"
      }
      env {
        name = "BANTORA_SMS_MAX_ATTEMPTS"
        value = "3"
      }
      
      # AI Service
      env {
        name  = "BANTORA_AI_GEMINI_URL"
        value = var.bantora_ai_gemini_url
      }
      env {
        name  = "BANTORA_AI_GEMINI_API_KEY"
        value = var.gemini_api_key
      }
      
      # JPA/Hibernate
      env {
        name  = "SPRING_JPA_PROPERTIES_HIBERNATE_DEFAULT_SCHEMA"
        value = "public"
      }
      env {
        name = "SPRING_JPA_hibernate_ddl-auto"
        value = "update"
      }
    }
    
    # VPC Access for Redis
    vpc_access {
      connector = google_vpc_access_connector.connector.id
      egress    = "PRIVATE_RANGES_ONLY"
    }

    # Cloud SQL Connection

  }
  deletion_protection = false
  depends_on = [google_artifact_registry_repository.bantora_repo, google_sql_database_instance.bantora_db, google_redis_instance.bantora_redis, google_project_service.run_api]
}

# Bantora Web Service
resource "google_cloud_run_v2_service" "bantora_web" {
  name     = "bantora-web"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/bantora-repo/bantora-web:${var.image_tag}"
      ports {
        container_port = 3080
      }
      resources {
        limits = {
          cpu    = "1000m"
          memory = "512Mi"
        }
      }

    }
  }
  deletion_protection = false
  depends_on = [google_project_service.run_api]
}

# Allow unauthenticated access to Web
resource "google_cloud_run_service_iam_member" "web_public" {
  location = google_cloud_run_v2_service.bantora_web.location
  service  = google_cloud_run_v2_service.bantora_web.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Allow unauthenticated access to API (Auth handled by app)
resource "google_cloud_run_service_iam_member" "api_public" {
  location = google_cloud_run_v2_service.bantora_api.location
  service  = google_cloud_run_v2_service.bantora_api.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
