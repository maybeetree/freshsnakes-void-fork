#!/bin/sh

over="3.14"
vers="3.13 3.12 3.11 3.10"

for ver in $vers
do
	diff \
		void-packages/srcpkgs/multi-python$over/template \
		void-packages/srcpkgs/multi-python$ver/template  \
		| grep -vE 'pkgname|version|py3_ver|checksum'
done
