#!/bin/sh

eecho() { echo "$@" >&2 ; }
pecho() { printf '%s' "$*" ; }
die() { eecho "$@"; exit 1; }
edie() { die "Failed to: $@"; }
try() {
	eval "$@" || {
		eecho "Failed to run: '$*'"
		kill "$$"
	}
}
mtry() {
	msg="$1"
	shift
	eval "$@" || {
		eecho "Failed: '$msg'"
		eecho "(command: $* )"
		kill "$$"
	}
}

pkgsdir="./void-packages/srcpkgs"

strip_dotslash() {
	sed 's|^./||' || edie "strip dotslash"
}

changed_pkgs() {
	pkgs="$(
		try git diff \
			--diff-filter=d \
			--name-only \
			HEAD~1..HEAD \
			-- "$pkgsdir" \
		| try strip_dotslash \
		| try cut -d '/' -f 3 \
		| try sort \
		| try uniq \
	)"

	#dirs="$(
	#	try find "$pkgsdir" -maxdepth 1 -mindepth 1 -type d \
	#	| try strip_dotslash \
	#	| try sort \
	#	| try uniq
	#)"

	pecho "$pkgs"
	#eecho "$dirs"


}

changed_pkgs
