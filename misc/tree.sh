#!/bin/bash
# Create ASCII dependency tree
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

getprio() { # Print build-essential and priority label
	if echo "$1" | grep '^Build-Essential' >/dev/null
	then
		printf "build-essential,"
	fi
	if echo "$1" | grep '^Essential' >/dev/null
	then
		printf "essential,"
	fi
	echo "$1" | grep '^Priority' | sed 's/.*Priority\: //'
}

getsize() { # Print Installed-Size
	echo "$1" | grep Installed-Size | sed 's/.*Installed-Size\: //'
}

branch() {
	i=$1
	for _ in $(seq 1 "$i")
	do
		printf '|    '
	done
	printf '+--- '
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
	prio=$(getprio "$info")
	size=$(getsize "$info")

	echo "$pkg [$ver] {$prio} ($size)"
	if grep "$pkgc $ver" "$tmp" > /dev/null
	then
		return 0
	fi
	echo "$pkgc $ver" >> "$tmp"

	for d in $dep
	do
		branch "$i"
		_tree "$((i+1))" "$d"
	done
}

tree() {
	tmp=$(mktemp || die 'mktemp failed')
	_tree 0 "$1" "$tmp"
}

if [ "$#" -ne 1 ]
then
	die "$USAGE"
fi

tree "$1"
