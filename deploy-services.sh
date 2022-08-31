#!/bin/sh

# replicas
APP_REPLICAS=2
API_REPLICAS=2
IMAGE_SERVICE_REPLICAS=2

# api envs
POSTGRES_HOST=
POSTGRES_USER=
POSTGRES_PASSWORD=
POSTGRES_DB=

# image service envs
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
BUCKET_NAME=

deploy_frontend() {
    docker service create \
        --name bearnaisee-app \
        --replicas $APP_REPLICAS \
        --publish 8080:80 \
        --env VUE_APP_API_URL=http://localhost:5000 \
        --env VUE_APP_IMAGE_SERVICE=http://localhost:8000 \
        hougesen/bearnaisee-app:master
}

deploy_api() {
    docker service create \
        --name bearnaisee-api \
        --replicas $API_REPLICAS \
        --publish 5000:5000 \
        --env PORT=5000 \
        --env NODE_ENV=production \
        --env POSTGRES_HOST="$POSTGRES_HOST" \
        --env POSTGRES_USER="$POSTGRES_USER" \
        --env POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
        --env POSTGRES_DB="$POSTGRES_DB" \
        hougesen/bearnaisee-api:master
}

deploy_image_service() {
    docker service create \
        --name image-service \
        --replicas $IMAGE_SERVICE_REPLICAS \
        --publish 8000:8000 \
        --env AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" \
        --env AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \
        --env BUCKET_NAME="$BUCKET_NAME" \
        hougesen/s3-image-service
}
