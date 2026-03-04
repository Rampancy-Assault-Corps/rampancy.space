#!/bin/bash
# Deployment script for rampancy_assault_corps_server

set -e

PROJECT_ID="rampancy-space"
REGION="us-central1"
SERVICE_NAME="rampancy-assault-corps-server"
IMAGE_NAME="gcr.io/$PROJECT_ID/$SERVICE_NAME"

echo "Building Docker image..."
docker build --platform linux/amd64 -t $IMAGE_NAME .

echo "Pushing to Container Registry..."
docker push $IMAGE_NAME

echo "Deploying to Cloud Run..."
gcloud run deploy $SERVICE_NAME \
    --image $IMAGE_NAME \
    --platform managed \
    --region $REGION \
    --project $PROJECT_ID \
    --allow-unauthenticated \
    --port 8080 \
    --memory 512Mi \
    --cpu 1 \
    --min-instances 0 \
    --max-instances 10

echo "Deployment complete!"
echo "Service URL: https://$SERVICE_NAME-$PROJECT_ID.$REGION.run.app"
