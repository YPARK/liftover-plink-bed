#!/bin/bash
#
# filter_rename_samples.bash
#########################
#
# Drops all samples not in `keep_list`
#
set -e
set -u

module load plink

KEEP_LIST=30_gen/relevant-samples.txt
SRC_DIR=40_plink
DST_DIR=41_subset
mkdir -p "$DST_DIR"

# find first .fam file in SRC_DIR
for fam in "$SRC_DIR"/*.fam ; do
	name=$(basename "$fam" .fam)
	plink --bfile "$SRC_DIR/$name" --keep "$KEEP_LIST" --out "$DST_DIR/$name" \
	  --make-bed | tee "$DST_DIR/${name}.log"
done
