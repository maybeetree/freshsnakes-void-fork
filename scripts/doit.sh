#!/bin/sh

eecho() { echo "$@" >&2 ; }
pecho() { printf '%s' "$*" ; }
die() { eecho "$@"; exit 1; }
edie() { die "Failed to: $*"; }
cd_ass() { cd "$1" || die "Failed to cd into ${2:-$1}" ; }
ass() { "$@" || die "Failed to run command: $*" ; }

upstream_path=./void-packages-upstream
upstream_url=https://github.com/void-linux/void-packages
merged_path=./merged
self_packages_path=./void-packages
upper_path=./upper
work_path=./work

get_upstream() {
	if [ ! -r "$upstream_path" ]
	then
		eecho "Cloning $upstream_url into $upstream_path ..."
		git clone "$upstream_url" "$upstream_path" \
			|| edie "clone void-packages repo"
	else
		eecho "void-packages already cloned, pulling..."
		git -C "$upstream_path" pull \
			|| edie "pull void-packages repo"
	fi
}

ensure_unshare() {
	if [ "$(id -u)" -eq 0 ]
	then
		eecho "am already root (container environment?), "
		eecho "should be able to mount overlayfs."
	else
		eecho "Am not root, unsharing..."
		unshare -rUm -- "$@" \
			|| edie "unshare"
	fi
}

mount_overlay() {
	eecho "mounting overlay..."
	mkdir -p "$merged_path" \
		|| edie "make mountpoint"
	mkdir -p "$upper_path" \
		|| edie "make upper dir"
	mkdir -p "$work_path" \
		|| edie "make work dir"
	mount -t overlay overlay \
		"-olowerdir=$self_packages_path:$upstream_path,upperdir=$upper_path,workdir=$work_path" \
		"$merged_path" \
		|| edie "mount overlay"
}

build_packages() {
	eecho "building packages..."
	cd_ass "$merged_path"
	export XBPS_ALLOW_CHROOT_BREAKOUT=1
	./xbps-src binary-bootstrap \
		|| edie "xbps binary-bootstrap"

	for ver in 3.14 #3.13 3.12
	do
		./xbps-src pkg multi-python$ver \
			|| edie "make package"
	done
}

_post_unshare() {
	mount_overlay
	build_packages
}

main() {
	get_upstream
	ensure_unshare "$0" "_post_unshare"
}

if [ -z "$1" ]
then
	main
	exit 0
fi

#shift 1

#echo cmd: "$@"

"$@"



