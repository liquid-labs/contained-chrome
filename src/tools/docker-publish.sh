#!/usr/bin/env bash

NAME=theliquidlabs/contained-chrome

CONTAINER_ID="$(docker container ls --filter name=${NAME} -q)"
docker container commit ${CONTAINER_ID} ${NAME}
docker push ${NAME}
