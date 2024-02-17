#!/bin/sh
# Convert benchmarking stderr to tsv file with the following columns:
# thr: number of threads used
# disk_sec: time taken to fetch reads from memory in seconds
# tot_sec: total time taken in seconds
# maxrss_gb: maximum resident set size (RAM usage) in gibibytes
# maxbat: size of the largest batch
# nread: number of reads
# bytes: file size in bytes
# diskminflt: number of soft page faults (without I/O) while fetching reads
# diskmajflt: number of hard page faults (with I/O) while fetching reads
# totminflt: total number of soft page faults
# totmajflt: total number of hard page faults
# usage: cat *.stderr | ./res2tsv.sh
hdr='thr	disk_sec	tot_sec	maxrss_gb	maxbat	nread	bytes	diskminflt	diskmajflt	totminflt	totmajflt'

in=$(mktemp)
cat /dev/stdin > "$in"

out1=$(mktemp)
out2=$(mktemp)

grep -E '^Using [0-9]+ threads' "$in" \
	| cut -d ' ' -f2 > "$out1"
grep '^Time for disc reading' "$in" \
	| cut -d ' ' -f5 \
	| paste "$out1" - > "$out2"
grep '^Time for getting samples' "$in" \
	| cut -d ' ' -f6 \
	| paste "$out2" - > "$out1"
grep 'peak RAM' "$in" \
	| cut -d '|' -f3 | cut -d ' ' -f5 \
	| paste "$out1" - > "$out2"
grep 'Largest batch' "$in" \
	| cut -d ' ' -f3 \
	| paste "$out2" - > "$out1"
grep 'Reads' "$in" \
	| cut -d ' ' -f2 \
	| paste "$out1" - > "$out2"
grep 'File size (bytes)' "$in" \
	| cut -d ' ' -f4 \
	| paste "$out2" - > "$out1"
grep -e '--- disc results ---' "$in" -A17 \
	| grep 'page reclaims (soft page faults)' \
	| cut -d ' ' -f6 \
	| paste "$out1" - > "$out2"
grep -e '--- disc results ---' "$in" -A17 \
	| grep 'page faults (hard page faults)' \
	| cut -d ' ' -f6 \
	| paste "$out2" - > "$out1"
grep -e '--- total results ---' "$in" -A17 \
	| grep 'page reclaims (soft page faults)' \
	| cut -d ' ' -f6 \
	| paste "$out1" - > "$out2"
grep -e '--- total results ---' "$in" -A17 \
	| grep 'page faults (hard page faults)' \
	| cut -d ' ' -f6 \
	| paste "$out2" - > "$out1"

echo "$hdr" | cat - "$out1"
