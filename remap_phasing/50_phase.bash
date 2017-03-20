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
RECOMPUTE=true


mkdir -p "$DST_DIR"
for x in "$SRC_DIR"/*.bim; do
	chr=$(basename "$x" .bim)
	export chr=${chr#chr_}
	export src_prefix="${x%.bim}"
	export dst_prefix="$DST_DIR/chr_${chr}.phased"
	export genetic_map=input_data/genetic_map_b37/genetic_map_chr_${chr}_combined_b37.txt
	[ -f $genetic_map ] || ( echo "unable to find $genetic_map. aborting"; exit 1)
	echo "Phasing $src_prefix ..."
	sbatch -o ${dst_prefix}.out -e ${dst_prefix}.err 50_phase.job
done

