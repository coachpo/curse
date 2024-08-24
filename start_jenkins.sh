#!/bin/bash

# Set variables for reuse
NETWORK_NAME="jenkins"
VOLUME_NAME="jenkins-data"
CONTAINER_NAME="jenkins-blueocean"
IMAGE_NAME="capy8ra/jenkins-blueocean:2.462.1-1"
HOST_PORT="8080"
AGENT_PORT="50000"
DOCKER_CERTS_VOLUME="jenkins-docker-certs"

# Create a Docker network for Jenkins if it doesn't already exist
if ! docker network inspect "$NETWORK_NAME" >/dev/null 2>&1; then
    docker network create "$NETWORK_NAME"
    echo "Docker network '$NETWORK_NAME' created."
else
    echo "Docker network '$NETWORK_NAME' already exists."
fi

# Create a Docker volume for Jenkins data if it does not already exist
if ! docker volume inspect "$VOLUME_NAME" >/dev/null 2>&1; then
    docker volume create "$VOLUME_NAME"
    echo "Docker volume '$VOLUME_NAME' created."
else
    echo "Docker volume '$VOLUME_NAME' already exists."
fi

# Run the Jenkins container
docker run \
  --name "$CONTAINER_NAME" \
  --restart=on-failure \
  --detach \
  --network "$NETWORK_NAME" \
  --env DOCKER_HOST=tcp://docker:2376 \
  --env DOCKER_CERT_PATH=/certs/client \
  --env DOCKER_TLS_VERIFY=1 \
  --publish "$HOST_PORT:8080" \
  --publish "$AGENT_PORT:50000" \
  --volume "$VOLUME_NAME:/var/jenkins_home" \
  --volume "$DOCKER_CERTS_VOLUME:/certs/client:ro" \
  --volume /var/run/docker.sock:/var/run/docker.sock \
  "$IMAGE_NAME"

# Check if Jenkins started successfully
if [ $? -eq 0 ]; then
    echo "Jenkins is running and accessible at http://localhost:$HOST_PORT"
else
    echo "Failed to start Jenkins. Please check the Docker logs for more details."
fi
