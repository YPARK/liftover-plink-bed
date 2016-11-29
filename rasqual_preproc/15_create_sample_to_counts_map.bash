#!/bin/bash
#
# preprocessing for 15_mergeASCounts.py
# Creates a mapping from sample_name to RNA_ASE_COUNTS.csv file
# TODO general cleanup
#
set -e
set -u

SRCD="$1"
SAMPLE_SUFFIX="${2-.csv}"
OUTFILE="output/sample_paths.txt"
echo Selecting sample files in $SRCD ending in $SAMPLE_SUFFIX
echo "Results stored in $OUTFILE"
for path in "$SRCD"/*"$SAMPLE_SUFFIX" ; do
  name=$(basename "$path" "$SAMPLE_SUFFIX")
  echo -e "$name\t$path"
done > "$OUTFILE"

