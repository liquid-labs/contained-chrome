#!/usr/bin/env bash

NAME=theliquidlabs/contained-chrome

# docker push ${NAME}:dev
docker image tag ${NAME}:dev ${NAME}:latest
docker image push ${NAME}:latest
