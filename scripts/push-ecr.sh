#!/bin/bash

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 753392824297.dkr.ecr.us-east-1.amazonaws.com

docker build -t prod-default-project-name ../nginx-docker

docker tag prod-default-project-name:latest 753392824297.dkr.ecr.us-east-1.amazonaws.com/prod-default-project-name:latest

docker push 753392824297.dkr.ecr.us-east-1.amazonaws.com/prod-default-project-name:latest