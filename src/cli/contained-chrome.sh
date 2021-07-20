#!/usr/bin/env bash

# better user output from @liquid-labs/bash-toolkit
import echoerr

IMAGE="${1:-theliquidlabs/contained-chrome}"

OS="$(uname -s)"

VNC_VIEWER_EXEC="/Applications/VNC Viewer.app/Contents/MacOS/vncviewer"
VNC_VIEWER_INSTALL_URL=https://www.realvnc.com/en/connect/download/vnc/
DOCKER_INSTALL_URL=https://docs.docker.com/get-docker/

# first, let's check if docker is present
if ! command -v docker &>/dev/null; then
  echoerrandexit "Docker is not installed locally:\n\n${DOCKER_INSTALL_URL}"
fi

# we will also need 'uuidgen' to generate a password TODO: move this to bash-toolkit and make it more robust
if command -v uuidgen &>/dev/null; then
  VNC_PASSWORD="$(uuidgen)"
fi

# running with '--detach' will cause docker to run in background and emit the newly created container ID
CONTAINER_ID="$(docker run \
  -p 5900:5900 \
  -e VNC_SERVER_PASSWORD="${VNC_PASSWORD}" \
  --detach \
  --user apps "${IMAGE}")"

# TODO SECURITY: Everything isn't so stable that we can rely on connections, but broadcasting the password is a security issue.
echofmt "Started container with ID:\n\n  ${CONTAINER_ID}\n\nVNC Password:\n\n  ${VNC_PASSWORD}\n"

is-docker-running() {
  [[ "$(docker container inspect -f '{{.State.Status}}' ${CONTAINER_ID})" == 'running' ]]
}

# now we go into a loop until everything looks ready to go
TRY_COUNT=1
TRY_LIMIT=5
SLEEP_SECS=3

while ! is-docker-running && (( ${TRY_COUNT} <= ${TRY_LIMIT} )); do
  echofmt "Waiting on docker container..."
  sleep ${SLEEP_SECS}
  TRY_COUNT=$(( ${TRY_COUNT} + 1 ))
done

if ! is-docker-running; then
  echofmt "Docker hasn't started..."
  exit 1
fi

is-ready() {
  # this is a marker dropped in from the bootstrap script
  docker exec -it ${CONTAINER_ID} test -f /home/apps/.ready
}

TRY_COUNT=1
while ! is-ready && (( ${TRY_COUNT} <= ${TRY_LIMIT} )); do
  echofmt "Waiting on docker startup script..."
  sleep ${SLEEP_SECS}
  TRY_COUNT=$(( ${TRY_COUNT} + 1 ))
done

if ! is-ready; then
  echofmt "Startup script failed to start..."
  exit 1
fi

# now we're ready to start the local VNC and connect to our docker
if [[ "${OS}" == 'Darwin' ]]; then
  if [[ -f "${VNC_VIEWER_EXEC}" ]]; then
    VNC_PASS="$(mktemp -t 'contained-chrome.')"
    docker cp ${CONTAINER_ID}:/home/apps/.x11vnc.pass "${VNC_PASS}"
    "${VNC_VIEWER_EXEC}" -passwd "${VNC_PASS}" 127.0.0.1
    rm -f "${VNC_PASS}"
  else
    echowarn -e "Falling back to built-in VNC. This has been observed to hang and may not perform as well. Consider installing RealVNC viewer:\n\n${VNC_VIEWER_INSTALL_URL}"
    open vnc://:${VNC_PASSWORD}@127.0.0.1
  fi
else
  echowarn "Your OS is not supported. Use the information above to manually connect a VNC client to the running docker container."
fi
