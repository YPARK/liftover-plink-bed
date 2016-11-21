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

function require() {
	bin="$1"
	mod="${2-$bin}"
	command -v "$bin" >/dev/null 2>&1 || module load "$mod"
	if ! command -v "$bin" > /dev/null 2>&1 ; then
		echo > /dev/stderr "Unable to loacate $bin. aborting ..."
		exit 1
	fi
}
require plink
require GenotypeHarmonizer.sh GenotypeHarmonizer
require shapeit
SRC_DIR=42_plink
DST_DIR=50_phased
RECOMPUTE=false


mkdir -p "$DST_DIR"
for x in "$SRC_DIR"/*.bim; do
	export prefix="${x%.bim}"
	export dst="$DST_DIR/$(basename $prefix).phased.vcf"
	echo "$prefix $dst"
	if [[ ! -f "$dst" || "$RECOMPUTE" = true ]] ; then
		echo "Phasing $prefix ..."
		sbatch -o ${dst}.out -e ${dst}.err 50_phase.job
	fi
done

