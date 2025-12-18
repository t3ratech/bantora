#!/bin/bash
echo "Validating Remote Bantora Services..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Fetch URLs from Terraform
API_URL=$(cd "$PROJECT_ROOT/terraform" && terraform output -raw bantora_api_url 2>/dev/null)
WEB_URL=$(cd "$PROJECT_ROOT/terraform" && terraform output -raw bantora_web_url 2>/dev/null)

if [ -z "$API_URL" ] || [ -z "$WEB_URL" ]; then
    echo "Error: Could not retrieve service URLs from Terraform."
    exit 1
fi

echo "API URL: $API_URL"
echo "WEB URL: $WEB_URL"

test_health() {
  URL=$1
  NAME=$2
  echo -n "Testing $NAME ($URL)... "
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$URL")
  if [ "$HTTP_CODE" -eq 200 ]; then
    echo "OK"
  else
    echo "FAILED (Code: $HTTP_CODE)"
  fi
}

test_health "${API_URL}/actuator/health" "API Service"
test_health "${WEB_URL}" "Web Frontend"

echo "Testing Auth Flow via Remote API..."
# Register
echo "Registering new user..."
TIMESTAMP=$(date +%s)
# Use a valid test phone number format +263 77 + last 7 digits of timestamp
# Ensure it's E.164 (phone number with coutry code)
PHONE_SUFFIX=${TIMESTAMP: -7}
PHONE_NUMBER="+26377${PHONE_SUFFIX}"
EMAIL="remote_${TIMESTAMP}@test.com"
PASSWORD="SecurePass${TIMESTAMP}!"

echo "Using Phone: $PHONE_NUMBER"

# Register
REGISTER_PAYLOAD="{\"phoneNumber\":\"$PHONE_NUMBER\",\"password\":\"$PASSWORD\",\"countryCode\":\"ZW\",\"preferredLanguage\":\"en\",\"preferredCurrency\":\"ZWL\",\"fullName\":\"Test User\",\"email\":\"$EMAIL\"}"
echo "Payload: $REGISTER_PAYLOAD"

curl -v -X POST -H "Content-Type: application/json" -d "$REGISTER_PAYLOAD" "${API_URL}/api/v1/auth/register"

# Login and get Token
echo -e "\nLogging in..."
LOGIN_PAYLOAD="{\"phoneNumber\":\"$PHONE_NUMBER\",\"password\":\"$PASSWORD\"}"
LOGIN_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -d "$LOGIN_PAYLOAD" "${API_URL}/api/v1/auth/login")

if echo "$LOGIN_RESPONSE" | grep -q "token"; then
  echo "Login OK"
  TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"token":"[^"]*' | cut -d'"' -f4)
  # Handle nested token if response is wrapped in data
  if [ -z "$TOKEN" ]; then
      # Try accessing accessToken from response like { "data": { "accessToken": "..." } }
      TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"accessToken":"[^"]*' | cut -d'"' -f4)
  fi
  
  if [ -n "$TOKEN" ]; then
      echo "Token: ${TOKEN:0:10}..."
  else
       echo "Token not found in response structure."
       echo "$LOGIN_RESPONSE"
  fi
  
else
  echo "Login FAILED"
  echo "Response: $LOGIN_RESPONSE"
fi
