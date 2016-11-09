#!/bin/bash
#
# filter_rename_samples.bash
#########################
#
# Script that renames a set of plink samples and drops all other samples
#
# requires a keep_list.csv file with two columns:
# 	old_name, new_name
#
# Only samples in keep_list.csv will be kept.
set -e
set -u

KEEP_CSV=$1
SRC_DIR=$2
DST_DIR=$3
TMP=$(mktemp -q -d --tmpdir=.)

# find first .fam file in SRC_DIR
SRC_FAM=$(find "$SRC_DIR" -name '*.fam' -print -quit)
TMP_FAM="$TMP/dst.fam"
TMP_KEEP="$TMP/dst.samples"
python filter_rename_samples.py "$KEEP_CSV" "$SRC_FAM" "${TMP_FAM%.fam}"

mkdir -p "$DST_DIR"
for fam in "$SRC_DIR"/*.fam ; do
	name=$(basename "$fam" .fam)
	plink --bfile "$SRC_DIR/$name" --fam "$TMP_FAM" --keep "$TMP_KEEP" --out "$DST_DIR/$name" --make-bed > /dev/null 2>&1
done
rm -fr $TMP
