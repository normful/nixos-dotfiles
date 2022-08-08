#!/usr/bin/env bash

set -o errexit
set -o xtrace
set -o pipefail

function finish {
  set +e
  docker kill nixos-arm-builder > /dev/null
  docker rm nixos-arm-builder > /dev/null
}
trap finish EXIT

echo "Building docker image"
docker build -t nixos-arm-builder .

echo "Running docker container detached to copy file"
docker run --name nixos-arm-builder --detach nixos-arm-builder sleep 10m > /dev/null

echo "Copying nixos.iso"
docker cp nixos-arm-builder:/tmp/nixos.iso .
