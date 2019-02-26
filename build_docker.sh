#!/bin/bash
set -eu

IMAGE=ikeyasu/colab-local:latest

docker build \
	-t ${IMAGE} \
	.

echo "Please run \`docker push ${IMAGE}\`"
