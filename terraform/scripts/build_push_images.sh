#!/bin/bash

image_tag=$image_tag
repo_url=$repo_url
service_name=$service_name
service_path="../services/${service_name}"

docker build -t ${repo_url}:${image_tag} ${service_path}
docker push ${repo_url}:${image_tag}