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
	export prefix="${bed%.bed}"
	echo "Phasing $prefix ..."
	sbatch phase.bash
done
