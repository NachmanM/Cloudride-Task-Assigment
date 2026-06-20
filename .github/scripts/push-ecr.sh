#!/bin/bash

TAG=$1

docker build -t ${ECR_REGISTRY}/${ECR_REPOSITORY}:${TAG} nginx-docker

docker push ${ECR_REGISTRY}/${ECR_REPOSITORY}:${TAG}