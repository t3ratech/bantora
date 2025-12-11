#!/bin/bash
set -e

# Determine Project Root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source credentials
if [ -f ~/gcp/credentials_bantora ]; then
    source ~/gcp/credentials_bantora
else
    echo "Error: ~/gcp/credentials_bantora file not found!"
    exit 1
fi

if [ -z "$GEMINI_API_KEY" ]; then
    echo "Error: GEMINI_API_KEY is not set in ~/gcp/credentials_bantora"
    exit 1
fi

# Check dependencies
if ! command -v gcloud &> /dev/null; then
    echo "Error: gcloud CLI is not installed."
    exit 1
fi

if ! command -v terraform &> /dev/null; then
    echo "Error: terraform is not installed."
    exit 1
fi

echo "Setting up GCP Infrastructure for Project: $GCP_PROJECT_ID"

# Authentication Check
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo "Not authenticated. Please login explicitly if needed."
    # gcloud auth login # Avoiding interactive login
fi

# Set Project
gcloud config set project "$GCP_PROJECT_ID"

# Initialize Terraform
cd "$PROJECT_ROOT/terraform"
terraform init

# Create Artifact Registry first
echo "Creating Artifact Registry..."
terraform apply -target=google_artifact_registry_repository.bantora_repo \
  -var="project_id=$GCP_PROJECT_ID" \
  -var="region=$GCP_REGION" \
  -var="db_password=$DB_PASSWORD" \
  -var="jwt_secret=$JWT_SECRET" \
  -var="gemini_api_key=$GEMINI_API_KEY" \
  -auto-approve

# Configure Docker
echo "Configuring Docker authentication..."
gcloud auth configure-docker "${GCP_REGION}-docker.pkg.dev" --quiet

# Generate Tag
IMAGE_TAG=$(date +%s)
echo "Deploying with TAG: $IMAGE_TAG"

# Build and Push Images
REPO_PREFIX="${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/bantora-repo"

build_push() {
    SERVICE=$1
    DIR=$2
    BUILD_ARGS=$3
    CONTEXT=${4:-.} # Default to current directory if not specified

    IMAGE_LATEST="${REPO_PREFIX}/${SERVICE}:latest"
    IMAGE_TAGGED="${REPO_PREFIX}/${SERVICE}:${IMAGE_TAG}"

    echo "------------------------------------------------"
    echo "Building $SERVICE (Context: $CONTEXT)..."
    echo "------------------------------------------------"

    (cd "$PROJECT_ROOT" && docker build --platform linux/amd64 -t "$IMAGE_LATEST" -t "$IMAGE_TAGGED" -f "${DIR}/Dockerfile" $BUILD_ARGS "$CONTEXT")

    echo "Pushing images..."
    docker push "$IMAGE_LATEST"
    docker push "$IMAGE_TAGGED"
}

# Build API (Needs root context for shared modules)
build_push "bantora-api" "bantora-api" "--build-arg API_INTERNAL_PORT=3081" "."

# Build Web (Needs local context for nginx.conf)
build_push "bantora-web" "bantora-web" "--build-arg WEB_INTERNAL_PORT=3080" "bantora-web"

# Full Deployment
echo "Deploying all resources via Terraform..."
terraform apply \
  -var="project_id=$GCP_PROJECT_ID" \
  -var="region=$GCP_REGION" \
  -var="db_password=$DB_PASSWORD" \
  -var="jwt_secret=$JWT_SECRET" \
  -var="gemini_api_key=$GEMINI_API_KEY" \
  -var="image_tag=$IMAGE_TAG" \
  -auto-approve

echo "================================================"
echo "GCP Setup Complete!"
echo "================================================"
terraform output
exit 0
