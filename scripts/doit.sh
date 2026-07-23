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

upstream_path=./void-packages-upstream
upstream_url=https://github.com/void-linux/void-packages
merged_path=./merged
self_packages_path=./void-packages
upper_path=./upper
work_path=./work
binpkgs_path=$merged_path/hostdir/binpkgs/

get_upstream() {
	if [ ! -r "$upstream_path" ]
	then
		eecho "Cloning $upstream_url into $upstream_path ..."
		mtry "clone void-packages repo" \
			git clone $GIT_CLONE_ARGS "$upstream_url" "$upstream_path"
	else
		eecho "void-packages already cloned, pulling..."
		mtry "pull void-packages repo" \
			git -C "$upstream_path" pull
	fi
}

ensure_unshare() {
	if [ "$(id -u)" -eq 0 ]
	then
		eecho "am already root (container environment?), "
		eecho "should be able to mount overlayfs."
		mtry "run without unshare (if this fails,
try running the container with --cap-add=SYS_ADMIN or
--privileged)" "$@"
	else
		eecho "Am not root, unsharing..."
		mtry "unshare" unshare -rUm -- "$@"
	fi
}

mount_overlay() {
	eecho "mounting overlay..."
	mtry "make mountpoint" mkdir -p "$merged_path"
	mtry "make upper dir" mkdir -p "$upper_path"
	mtry "make work dir" mkdir -p "$work_path"
	mtry "mount overlay" \
		mount -t overlay overlay \
		"-olowerdir=$self_packages_path:$upstream_path,upperdir=$upper_path,workdir=$work_path" \
		"$merged_path"
}

build_packages() {
	eecho "building packages..."
	#cd_ass "$merged_path"
	export XBPS_ALLOW_CHROOT_BREAKOUT=1
	(
		try cd "$merged_path"
		mtry "xbps binary-bootstrap" ./xbps-src binary-bootstrap
	)

	#for ver in 3.14 3.13 3.12 3.11 3.10
	for pkg in $(try cd "$self_packages_path/srcpkgs" ; try ls ; )
	do
		#pkg="$(pecho "$pkg" | try cut -d/ -f4)"
		eecho "building: $pkg"
		if [ -e $binpkgs_path/$pkg*.xbps ]
		then
			eecho "$pkg: already built"
			continue
		fi
		(
			try cd "$merged_path"
			mtry "make pkg" ./xbps-src pkg "$pkg"
		)
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



