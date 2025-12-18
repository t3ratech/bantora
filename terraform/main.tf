terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.51.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.10.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

data "google_project" "project" {}

# Grant Cloud SQL Client role to default Compute Service Account
resource "google_project_iam_member" "cloud_run_sql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
}

# Enable required APIs
resource "google_project_service" "run_api" {
  service = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "sqladmin_api" {
  service = "sqladmin.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "artifactregistry_api" {
  service = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "redis_api" {
  service = "redis.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "vpcaccess_api" {
  service = "vpcaccess.googleapis.com"
  disable_on_destroy = false
}

# Artifact Registry
resource "google_artifact_registry_repository" "bantora_repo" {
  location      = var.region
  repository_id = "bantora-repo"
  description   = "Docker repository for Bantora services"
  format        = "DOCKER"
  depends_on    = [google_project_service.artifactregistry_api]
}

# VPC Network (Required for Redis/VPC Access)
resource "google_compute_network" "vpc_network" {
  name = "bantora-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "vpc_subnet" {
  name          = "bantora-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.vpc_network.id
}

# Serverless VPC Acess Connector (For Cloud Run to reach Redis)
resource "google_vpc_access_connector" "connector" {
  name          = "bantora-vpc-conn"
  region        = var.region
  ip_cidr_range = "10.8.0.0/28"
  network       = google_compute_network.vpc_network.name
  min_instances = 2
  max_instances = 3
  depends_on    = [google_project_service.vpcaccess_api]
}

resource "google_project_service" "servicenetworking_api" {
  service = "servicenetworking.googleapis.com"
  disable_on_destroy = false
}

# Private IP Address for Cloud SQL
resource "google_compute_global_address" "private_ip_address" {
  name          = "bantora-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc_network.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
  depends_on              = [google_project_service.servicenetworking_api]
}

# Cloud SQL (PostgreSQL 16)
resource "google_sql_database_instance" "bantora_db" {
  name             = "bantora-db-instance-${random_id.db_suffix.hex}"
  database_version = "POSTGRES_16"
  region           = var.region
  depends_on       = [google_project_service.sqladmin_api, google_service_networking_connection.private_vpc_connection]

  settings {
    tier = "db-custom-1-3840"
    edition = "ENTERPRISE"
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.vpc_network.id
    }
  }
  deletion_protection = false
}

resource "time_sleep" "wait_for_cloudsql" {
  depends_on      = [google_sql_database_instance.bantora_db]
  create_duration = "60s"
}

resource "random_id" "db_suffix" {
  byte_length = 4
}

resource "google_sql_database" "database" {
  name     = "bantora_db"
  instance = google_sql_database_instance.bantora_db.name
  depends_on = [time_sleep.wait_for_cloudsql]
}

resource "google_sql_user" "users" {
  name     = var.db_user
  instance = google_sql_database_instance.bantora_db.name
  password = var.db_password
  depends_on = [time_sleep.wait_for_cloudsql]
}

# Redis (Memorystore)
resource "google_redis_instance" "bantora_redis" {
  name           = "bantora-redis"
  memory_size_gb = 1
  region         = var.region
  tier           = "BASIC"

  authorized_network = google_compute_network.vpc_network.id
  redis_version      = "REDIS_7_0"
  
  depends_on = [google_project_service.redis_api]
}
