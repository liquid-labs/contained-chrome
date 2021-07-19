#!/usr/bin/env bash

IMAGE="${1}"

OS="$(uname -s)"

VNC_VIEWER_EXEC="/Applications/VNC Viewer.app/Contents/MacOS/vncviewer"
VNC_VIEWER_INSTALL_URL=https://www.realvnc.com/en/connect/download/vnc/
DOCKER_INSTALL_URL=https://docs.docker.com/get-docker/

if ! command -v docker &>/dev/null; then
  echo -e "Docker is not installed locally:\n\n${DOCKER_INSTALL_URL}"
fi

if [[ "${OS}" == 'Darwin' ]] && ! ls "${VNC_VIEWER_EXEC}" &>/dev/null; then
  echo -e "It appears that VNC Viewer is not installed. Try:\n\n${VNC_VIEWER_INSTALL_URL}"
fi

if command -v uuidgen &>/dev/null; then
  VNC_PASSWORD="$(uuidgen)"
fi

CONTAINER_ID="$(docker run \
  -p 5900:5900 \
  -e VNC_SERVER_PASSWORD="${VNC_PASSWORD}" \
  --detach \
  --user apps "${IMAGE}")"

echo -e "Started container with ID:\n\n  ${CONTAINER_ID}\n\nVNC Password:\n\n  ${VNC_PASSWORD}\n"

is-docker-running() {
  [[ "$(docker container inspect -f '{{.State.Status}}' ${CONTAINER_ID})" == 'running' ]]
}

TRY_COUNT=1
TRY_LIMIT=5
SLEEP_SECS=3

while ! is-docker-running && (( ${TRY_COUNT} <= ${TRY_LIMIT} )); do
  echo "Waiting on docker container..."
  sleep ${SLEEP_SECS}
  TRY_COUNT=$(( ${TRY_COUNT} + 1 ))
done

if ! is-docker-running; then
  echo "Docker hasn't started..."
  exit 1
fi

is-ready() {
  docker exec -it ${CONTAINER_ID} test -f /home/apps/.ready
}

TRY_COUNT=1
while ! is-ready && (( ${TRY_COUNT} <= ${TRY_LIMIT} )); do
  echo "Waiting on docker startup script..."
  sleep ${SLEEP_SECS}
  TRY_COUNT=$(( ${TRY_COUNT} + 1 ))
done

if ! is-ready; then
  echo "Startup script failed to start..."
  exit 1
fi

if [[ "${OS}" == 'Darwin' ]]; then
  if [[ -f "${VNC_VIEWER_EXEC}" ]]; then
    VNC_PASS="$(mktemp -t 'contained-chrome.')"
    docker cp ${CONTAINER_ID}:/home/apps/.x11vnc.pass "${VNC_PASS}"
    "${VNC_VIEWER_EXEC}" -passwd "${VNC_PASS}" 127.0.0.1
    rm -f "${VNC_PASS}"
  else
    echo -e "Falling back to built-in VNC. This has been observed to hang and may not perform as well. Consider installing RealVNC viewer:\n\n${VNC_VIEWER_INSTALL_URL}"
    open vnc://:${VNC_PASSWORD}@127.0.0.1
  fi
fi
