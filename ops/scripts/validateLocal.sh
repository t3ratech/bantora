#!/bin/bash
echo "Validating Local Bantora Services..."

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

# Bantora Ports:
# Web: 3080
# API: 3081
# Gateway: 3083 (Not used in cloud deployment, but checking local)
# Cloud Run deployment uses API service as the backend entry point directly if Gateway is omitted.

test_health "http://localhost:3080" "Web Frontend"
test_health "http://localhost:3081/actuator/health" "API Service"
test_health "http://localhost:3083/actuator/health" "Gateway Service"

echo "Testing Auth Flow via API..."
# Register
echo "Registering testuser_local..."
TIMESTAMP=$(date +%s)
PHONE_SUFFIX=${TIMESTAMP: -7}
PHONE_NUMBER="+26377${PHONE_SUFFIX}"
EMAIL="local_${TIMESTAMP}@test.com"
PASSWORD="SecurePass${TIMESTAMP}!"

REGISTER_PAYLOAD="{\"phoneNumber\":\"$PHONE_NUMBER\",\"password\":\"$PASSWORD\",\"countryCode\":\"ZW\",\"preferredLanguage\":\"en\",\"preferredCurrency\":\"ZWL\",\"fullName\":\"Test User Local\",\"email\":\"$EMAIL\"}"

curl -s -X POST -H "Content-Type: application/json" -d "$REGISTER_PAYLOAD" http://localhost:3081/api/v1/auth/register | grep "success" && echo "Register OK" || echo "Register FAILED"

# Login
echo "Logging in..."
LOGIN_PAYLOAD="{\"phoneNumber\":\"$PHONE_NUMBER\",\"password\":\"$PASSWORD\"}"
curl -s -X POST -H "Content-Type: application/json" -d "$LOGIN_PAYLOAD" http://localhost:3081/api/v1/auth/login | grep "token" && echo "Login OK" || echo "Login FAILED"
