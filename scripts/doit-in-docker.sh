#!/bin/sh

eecho() { echo "$@" >&2 ; }
pecho() { printf '%s' "$*" ; }
die() { eecho "$@"; exit 1; }
edie() { die "Failed to: $*"; }
try() {
	"$@" || {
		eecho ''
		eecho "Failed to run: '$*'"
		eecho ''
		kill "$$"
	}
}
mtry() {
	msg="$1"
	shift
	"$@" || {
		eecho ''
		eecho "Failed: '$msg'"
		eecho "(command: $* )"
		eecho ''
		kill "$$"
	}
}

image=freshsnakes-void

if [ -n "$DOCKER_CMD" ]
then
	eecho "Using custom docker command: $DOCKER_CMD"
	docker="$DOCKER_CMD"
else
	docker="docker"
fi

if [ -z "$($docker image ls --format json "$image")" ]
then
	eecho "No docker image called '$image', building..."
	try $docker build . --tag "$image"
fi

try $docker run \
	--rm \
	-v .:/app \
	--workdir /app \
	--cap-add=SYS_ADMIN \
	"$image" \
	./scripts/doit.sh
	


