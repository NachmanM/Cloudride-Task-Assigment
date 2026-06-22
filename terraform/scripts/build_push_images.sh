#!/bin/bash

image_tag=$image_tag
repo_url=$repo_url
service_name=$service_name
region=$region
service_path="../services/${service_name}"

registry=$(echo $repo_url | cut -d'/' -f1)
aws ecr get-login-password --region $region | docker login --username AWS --password-stdin $registry

docker build -t ${repo_url}:${image_tag} ${service_path}
docker push ${repo_url}:${image_tag}
