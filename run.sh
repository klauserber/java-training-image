#!/usr/bin/env sh

REGISTRY_NAME=isi006
IMAGE_NAME=java-training

docker run -it --rm -p 8080:8080 \
  ${REGISTRY_NAME}/${IMAGE_NAME}:latest
