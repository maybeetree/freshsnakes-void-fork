#!/bin/sh

for pkg in upper/hostdir/binpkgs/*.xbps
do
	echo "check $pkg..."
	would_clobber=0
	files=$(tar tf "$pkg")
	for file in $files
	do
		# cut off the `./`
		file="$(echo "$file" | tail -c +2)"

		if [ -r "$file" ]
		then
			echo "Would clobber: $file"
			would_clobber="$(expr "$would_clobber" + 1)"
		fi
	done
	echo "...would clobber $would_clobber files"
done

