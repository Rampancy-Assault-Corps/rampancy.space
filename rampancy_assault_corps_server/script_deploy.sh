#!/bin/bash

set -e

cd "$(dirname "$0")/.."

CONFIG_ENV_FILE="config/deploy.env"

if [ -f "$CONFIG_ENV_FILE" ]; then
    set -a
    . "$CONFIG_ENV_FILE"
    set +a
fi

gcloud config set account "${DEPLOY_ACCOUNT:-psycho@arcane.art}"

PROJECT_ID="rampancy-space"
REGION="us-central1"
SERVICE_NAME="rampancy-assault-corps-server"
IMAGE_NAME="gcr.io/$PROJECT_ID/$SERVICE_NAME"
ENABLE_ACCOUNT_LINKING="${ENABLE_ACCOUNT_LINKING:-false}"
ENV_VARS_FILE="$(mktemp)"

cleanup() {
    rm -f "$ENV_VARS_FILE"
}

trap cleanup EXIT

is_truthy() {
    case "${1:-}" in
        1|true|TRUE|True|yes|YES|Yes|on|ON|On)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

require_env() {
    local key="$1"
    local value="${!key}"

    if [ -z "$value" ]; then
        echo "[Error]: Missing required env var: $key"
        exit 1
    fi
}

yaml_escape() {
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

append_env() {
    local key="$1"
    local value="$2"

    printf '%s: "%s"\n' "$key" "$(yaml_escape "$value")" >> "$ENV_VARS_FILE"
}

append_env "GOOGLE_CLOUD_PROJECT" "$PROJECT_ID"
append_env "GCE_METADATA_HOST" "169.254.169.254"

if is_truthy "$ENABLE_ACCOUNT_LINKING"; then
    ENABLE_ACCOUNT_LINKING="true"
    require_env "DISCORD_CLIENT_ID"
    require_env "DISCORD_CLIENT_SECRET"
    require_env "DISCORD_REDIRECT_URI"
    require_env "BUNGIE_CLIENT_ID"
    require_env "BUNGIE_CLIENT_SECRET"
    require_env "BUNGIE_REDIRECT_URI"
    require_env "BUNGIE_API_KEY"
    require_env "SESSION_SIGNING_KEY_BASE64"
    require_env "TOKEN_ENCRYPTION_KEY_BASE64"

    if [ -z "${OAUTH_STATE_SIGNING_KEY_BASE64:-}" ]; then
        OAUTH_STATE_SIGNING_KEY_BASE64="$SESSION_SIGNING_KEY_BASE64"
    fi

    append_env "ENABLE_ACCOUNT_LINKING" "$ENABLE_ACCOUNT_LINKING"
    append_env "DISCORD_CLIENT_ID" "$DISCORD_CLIENT_ID"
    append_env "DISCORD_CLIENT_SECRET" "$DISCORD_CLIENT_SECRET"
    append_env "DISCORD_REDIRECT_URI" "$DISCORD_REDIRECT_URI"
    append_env "BUNGIE_CLIENT_ID" "$BUNGIE_CLIENT_ID"
    append_env "BUNGIE_CLIENT_SECRET" "$BUNGIE_CLIENT_SECRET"
    append_env "BUNGIE_REDIRECT_URI" "$BUNGIE_REDIRECT_URI"
    append_env "BUNGIE_API_KEY" "$BUNGIE_API_KEY"
    append_env "SESSION_SIGNING_KEY_BASE64" "$SESSION_SIGNING_KEY_BASE64"
    append_env "OAUTH_STATE_SIGNING_KEY_BASE64" "$OAUTH_STATE_SIGNING_KEY_BASE64"
    append_env "TOKEN_ENCRYPTION_KEY_BASE64" "$TOKEN_ENCRYPTION_KEY_BASE64"
    append_env "RAC_SESSION_MAX_AGE_SECONDS" "${RAC_SESSION_MAX_AGE_SECONDS:-86400}"
    append_env "RAC_OAUTH_STATE_MAX_AGE_SECONDS" "${RAC_OAUTH_STATE_MAX_AGE_SECONDS:-600}"
else
    ENABLE_ACCOUNT_LINKING="false"
    echo "[Warn]: ENABLE_ACCOUNT_LINKING=false. OAuth routes will remain disabled."
    append_env "ENABLE_ACCOUNT_LINKING" "$ENABLE_ACCOUNT_LINKING"
fi

echo "Submitting build to Google Cloud Build..."
gcloud builds submit --config cloudbuild.yaml --project "$PROJECT_ID"

echo "Deploying to Cloud Run..."
gcloud run deploy "$SERVICE_NAME" \
    --image "$IMAGE_NAME" \
    --platform managed \
    --region "$REGION" \
    --project "$PROJECT_ID" \
    --allow-unauthenticated \
    --port 8080 \
    --memory 1Gi \
    --cpu 1 \
    --min-instances 0 \
    --max-instances 10 \
    --env-vars-file "$ENV_VARS_FILE"

echo "Deployment complete!"
echo "Service URL: https://$SERVICE_NAME-$PROJECT_ID.$REGION.run.app"
