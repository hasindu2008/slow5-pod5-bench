#!/bin/bash
# Create dependency tree in LaTeX
# usage: ./tree.sh <pkg>

USAGE="$0 <pkg>"

die() {
	echo "$1" 2>&1
	exit 1
}

pkgclean() { # Remove version
	echo "$1" | sed 's/(.*)//'
}

aptprep() { # Remove trailing brackets and version if > symbol
	echo "$1" | sed 's/(//' | sed 's/)//' | sed 's/>.*//'
}

getinfo() {
	local pkg
	pkg=$(aptprep "$1")
	apt info "$pkg" 2>/dev/null || die "apt failed for $pkg"
}

getver() {
	echo "$1" | grep 'Version' | sed 's/Version\: //'
}

getdep() { # Removes version spaces, optional packages, commas
	echo "$1" | grep 'Depends' |
		sed 's/.*Depends\: //' |\
		sed 's/ (\([=<>]*\) \([^)]*\))/(\1\2)/g' |\
		sed 's/|[^,]*//g' |\
		sed 's/,//g'
}

_tree() {
	local i
	local dep

	i=$1
	pkg=$2
	pkgc=$(pkgclean "$pkg")

	info=$(getinfo "$pkg")
	ver=$(getver "$info")
	dep=$(getdep "$info")

	if [ "$i" = 0 ]
	then
		echo "\node{$pkgc}"
	else
		echo "\child{node{$pkgc}"
	fi
	if grep "$pkgc $ver" "$tmp" > /dev/null
	then
		return 0
	fi
	echo "$pkgc $ver" >> "$tmp"

	for d in $dep
	do
		_tree "$((i+1))" "$d"
	done
	echo "}"
}

tree() {
	tmp=$(mktemp || die 'mktemp failed')
	_tree 0 "$1" "$tmp"
	echo ";"
}

begin() {
	echo '\documentclass{article}
\usepackage{tikz}
\begin{document}'
}

end() {
	echo '\end{tikzpicture}'
}

if [ "$#" -ne 1 ]
then
	die "$USAGE"
fi

begin
tree "$1"
end
