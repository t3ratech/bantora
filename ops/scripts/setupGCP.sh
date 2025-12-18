#!/bin/bash
set -e

# Determine Project Root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

if [ -f "$PROJECT_ROOT/.env" ]; then
    set -a
    source "$PROJECT_ROOT/.env"
    set +a
fi

# Source credentials
if [ -f ~/.gcp/credentials_bantora ]; then
    source ~/.gcp/credentials_bantora
else
    echo "Error: ~/.gcp/credentials_bantora file not found!"
    exit 1
fi

if [ -n "$BANTORA_JWT_SECRET" ] && [ -z "$JWT_SECRET" ]; then
    export JWT_SECRET="$BANTORA_JWT_SECRET"
fi

if [ -n "$BANTORA_AI_GEMINI_API_KEY" ] && [ -z "$GEMINI_API_KEY" ]; then
    export GEMINI_API_KEY="$BANTORA_AI_GEMINI_API_KEY"
fi

if [ -z "$GCP_PROJECT_ID" ]; then
    echo "Error: GCP_PROJECT_ID is not set in ~/.gcp/credentials_bantora"
    exit 1
fi

if [ -z "$GCP_REGION" ]; then
    echo "Error: GCP_REGION is not set in ~/.gcp/credentials_bantora"
    exit 1
fi

if [ -z "$DB_PASSWORD" ]; then
    echo "Error: DB_PASSWORD is not set in ~/.gcp/credentials_bantora"
    exit 1
fi

if [ -z "$JWT_SECRET" ]; then
    echo "Error: JWT_SECRET (or BANTORA_JWT_SECRET) is not set in ~/.gcp/credentials_bantora"
    exit 1
fi

if [ -z "$GEMINI_API_KEY" ]; then
    echo "Error: GEMINI_API_KEY is not set in ~/.gcp/credentials_bantora"
    exit 1
fi

if [ -z "$BANTORA_SMS_PROVIDER" ]; then
    echo "Error: BANTORA_SMS_PROVIDER is not set"
    exit 1
fi

if [ -z "$BANTORA_SMS_ACCOUNT_SID" ]; then
    echo "Error: BANTORA_SMS_ACCOUNT_SID is not set"
    exit 1
fi

if [ -z "$BANTORA_SMS_AUTH_TOKEN" ]; then
    echo "Error: BANTORA_SMS_AUTH_TOKEN is not set"
    exit 1
fi

if [ -z "$BANTORA_SMS_FROM_NUMBER" ]; then
    echo "Error: BANTORA_SMS_FROM_NUMBER is not set"
    exit 1
fi

if [ -z "$BANTORA_SMS_VERIFICATION_CODE_LENGTH" ]; then
    echo "Error: BANTORA_SMS_VERIFICATION_CODE_LENGTH is not set"
    exit 1
fi

if [ -z "$BANTORA_SMS_VERIFICATION_CODE_EXPIRY_MINUTES" ]; then
    echo "Error: BANTORA_SMS_VERIFICATION_CODE_EXPIRY_MINUTES is not set"
    exit 1
fi

if [ -z "$BANTORA_SMS_MAX_ATTEMPTS" ]; then
    echo "Error: BANTORA_SMS_MAX_ATTEMPTS is not set"
    exit 1
fi

export TF_INPUT=0

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
  -var="bantora_sms_provider=$BANTORA_SMS_PROVIDER" \
  -var="bantora_sms_account_sid=$BANTORA_SMS_ACCOUNT_SID" \
  -var="bantora_sms_auth_token=$BANTORA_SMS_AUTH_TOKEN" \
  -var="bantora_sms_from_number=$BANTORA_SMS_FROM_NUMBER" \
  -var="bantora_sms_verification_code_length=$BANTORA_SMS_VERIFICATION_CODE_LENGTH" \
  -var="bantora_sms_verification_code_expiry_minutes=$BANTORA_SMS_VERIFICATION_CODE_EXPIRY_MINUTES" \
  -var="bantora_sms_max_attempts=$BANTORA_SMS_MAX_ATTEMPTS" \
  -input=false \
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

echo "Ensuring Cloud SQL instance is ready..."
terraform apply \
  -target=google_sql_database_instance.bantora_db \
  -var="project_id=$GCP_PROJECT_ID" \
  -var="region=$GCP_REGION" \
  -var="db_password=$DB_PASSWORD" \
  -var="jwt_secret=$JWT_SECRET" \
  -var="gemini_api_key=$GEMINI_API_KEY" \
  -var="image_tag=$IMAGE_TAG" \
  -var="bantora_sms_provider=$BANTORA_SMS_PROVIDER" \
  -var="bantora_sms_account_sid=$BANTORA_SMS_ACCOUNT_SID" \
  -var="bantora_sms_auth_token=$BANTORA_SMS_AUTH_TOKEN" \
  -var="bantora_sms_from_number=$BANTORA_SMS_FROM_NUMBER" \
  -var="bantora_sms_verification_code_length=$BANTORA_SMS_VERIFICATION_CODE_LENGTH" \
  -var="bantora_sms_verification_code_expiry_minutes=$BANTORA_SMS_VERIFICATION_CODE_EXPIRY_MINUTES" \
  -var="bantora_sms_max_attempts=$BANTORA_SMS_MAX_ATTEMPTS" \
  -input=false \
  -auto-approve

DB_INSTANCE_NAME=$(terraform state show -no-color google_sql_database_instance.bantora_db | awk -F '=' '/^[[:space:]]*name[[:space:]]*=/{v=$2; gsub(/^[[:space:]]+|[[:space:]]+$/, "", v); gsub(/^\"|\"$/, "", v); print v; exit}')

if [ -z "$DB_INSTANCE_NAME" ]; then
    echo "Error: Failed to determine Cloud SQL instance name from Terraform state"
    exit 1
fi

echo "Waiting for Cloud SQL instance to be RUNNABLE: $DB_INSTANCE_NAME"
SQL_STATE=""
for i in $(seq 1 60); do
    if SQL_STATE=$(gcloud sql instances describe "$DB_INSTANCE_NAME" --project "$GCP_PROJECT_ID" --format="value(state)"); then
        echo "Attempt $i/60: Cloud SQL state: $SQL_STATE"
    else
        SQL_STATE=""
        echo "Attempt $i/60: Cloud SQL state: (not available yet)"
    fi
    if [ "$SQL_STATE" = "RUNNABLE" ]; then
        break
    fi
    sleep 10
done

if [ "$SQL_STATE" != "RUNNABLE" ]; then
    echo "Error: Cloud SQL instance did not become RUNNABLE in time. Current state: $SQL_STATE"
    exit 1
fi

# Full Deployment
echo "Deploying all resources via Terraform..."
terraform apply \
  -var="project_id=$GCP_PROJECT_ID" \
  -var="region=$GCP_REGION" \
  -var="db_password=$DB_PASSWORD" \
  -var="jwt_secret=$JWT_SECRET" \
  -var="gemini_api_key=$GEMINI_API_KEY" \
  -var="image_tag=$IMAGE_TAG" \
  -var="bantora_sms_provider=$BANTORA_SMS_PROVIDER" \
  -var="bantora_sms_account_sid=$BANTORA_SMS_ACCOUNT_SID" \
  -var="bantora_sms_auth_token=$BANTORA_SMS_AUTH_TOKEN" \
  -var="bantora_sms_from_number=$BANTORA_SMS_FROM_NUMBER" \
  -var="bantora_sms_verification_code_length=$BANTORA_SMS_VERIFICATION_CODE_LENGTH" \
  -var="bantora_sms_verification_code_expiry_minutes=$BANTORA_SMS_VERIFICATION_CODE_EXPIRY_MINUTES" \
  -var="bantora_sms_max_attempts=$BANTORA_SMS_MAX_ATTEMPTS" \
  -input=false \
  -auto-approve

echo "================================================"
echo "GCP Setup Complete!"
echo "================================================"
terraform output
exit 0
