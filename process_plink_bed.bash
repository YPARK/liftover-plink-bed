#!/bin/bash

# This is the main script file
#
# Accepts a "raw" binary PLINK fileset and a csv file of sample subsets
# and proper names.
#
# Subsets, renames and changes reference genome.
#
set -u
set -e

KEEP_CSV=$1
SRC_DIR=$2
DST_DIR=$3
TMP=$(mktemp -q -d --tmpdir=.)

echo "Renaming and filtering ..."
bash filter_rename_samples.bash "$KEEP_CSV" "$SRC_DIR" "$TMP"
# input files sometimes has format chr_N .. , change to chrN
if compgen -G "$TMP/chr_*" ; then
	rename chr_ chr "$TMP"/chr_*
fi

echo "Changing reference genome ..."
bash change_plink_reference_genome.bash "$TMP" "$DST_DIR"
rm -fr "$TMP"

echo "Phasing and creating .vcf file"
for bed in "$DST_DIR"/*.bed ; do
	prefix="${bed%.bed}"
	chr=$(basename "$prefix")
	shapeit --input-bed "$prefix" \
		--input-map genetic_map_b37/genetic_map_${chr}_combined_b37.txt \
		--output-max "${prefix}.phased.haps" "${prefix}.phased.sample"
	shapeit -convert \
		--input-haps "${prefix}.phased" \
        	--output-vcf "${prefix}.phased.vcf"
done
