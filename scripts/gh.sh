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

check_remote_image() {
	image="$1"
	docker manifest inspect "$image"
}

#get_latest_tag() {
#	git describe --tags --abbrev=0
#}
#
#get_previous_tag() {
#	git describe --abbrev=0 --tags \
#		"$(git rev-list --tags --skip=1  --max-count=1)"
#}

# These versions should work inside a github actions run
# (i.e. detached head state)
get_latest_tag() {
	git fetch --tags --force >/dev/null 2>&1
	git describe --tags --abbrev=0 "$(git rev-list --tags --max-count=1)"
}

get_previous_tag() {
	git fetch --tags --force >/dev/null 2>&1
	git describe --tags --abbrev=0 "$(git rev-list --tags --skip=1 --max-count=1)"
}

get_changes_since() {
	rev=$1
	shift
	git diff --name-only "$rev" -- "$@"
}

build_and_push_image() {
	image="$1"
	try docker build . --tag "$image"
	try docker push "$image"
}

#pull_image() {
#	image="$1"
#	try docker pull "$image"
#}

get_latest_assets() {
	repo="$1"
	#latest_tag="$(
	#	gh release list \
	#	-R "$repo" \
	#	--json tagName,isLatest \
	#	--jq '.[]|select(.isLatest).tagName' \
	#)"

	#if [ -z "$latest_tag" ]
	#then
	#	eecho "No latest release found."
	#	return 0
	#fi

	output="$(gh release download \
		-p "*" \
		-D ./upper/hostdir/binpkgs \
		-R "$repo" \
	)" || {
		if pecho "$output" | grep 'release not found'
		then
			eecho "No latest release found."
			return 0
		fi
		die "Unknown error, bailing!"
	}

	eecho "downloaded successfully"
}

build_image_if_needed() {
	image="$1"

	if ! check_remote_image "$image"
	then
		eecho "Image does not exist on ghcr, building image!"
		build_and_push_image "$image"
		return 0
	fi

	if ! get_latest_tag
	then
		eecho "No latest tag found, building image!"
		build_and_push_image "$image"
		return 0
	fi

	if ! get_previous_tag
	then
		eecho "No previous tag found, building image!"
		build_and_push_image "$image"
		return 0
	fi

	previous_tag="$(try get_previous_tag)"
	changes_since="$(try get_changes_since "$previous_tag" ./Dockerfile)"

	if [ -n "$changes_since" ]
	then
		eecho "Dockerfile changed, building image!"
		build_and_push_image "$image"
		return 0
	fi

	eecho "No need to rebuild image!"
	#pull_image "$image"
	return 0
}

if [ -z "$1" ]
then
	die "Specify command."
fi

"$@"

