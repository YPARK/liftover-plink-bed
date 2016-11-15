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
require liftOver liftOverUcsc
require GenotypeHarmonizer.sh GenotypeHarmonizer
require shapeit
require tabix

KEEP_CSV=$1
SRC_DIR=$2
DST_DIR=$3
TMP=tmp

RECOMPUTE=false

if [[ ! -d "$TMP/10_filter" || "$RECOMPUTE" = true ]] ; then
	echo "Renaming and filtering ..."
	./filter_rename_samples.bash "$KEEP_CSV" "$SRC_DIR" "$TMP/10_filter"
	# input files sometimes has format chr_N .. , change to chrN
	if compgen -G "$TMP/10_filter/chr_*" > /dev/null ; then
		rename chr_ chr "$TMP/10_filter/"chr_*
	fi
else
	echo "Skipping renaming and filtering."
fi
if [[ ! -d "$TMP/20_liftover" || "$RECOMPUTE" = true ]] ; then
	echo "Changing reference genome ..."
	./change_plink_reference_genome.bash "$TMP/10_filter" "$TMP/20_liftover"
else
	echo "Skipping change reference genome ..."
fi

if [[ ! -d "$TMP/30_aligned" || "$RECOMPUTE" = true ]] ; then
	./raul_startAlign.sh "$TMP/20_liftover" "$TMP/30_aligned"
fi

echo "Slurm jobs aligning SNPs to reference needs to finish before continuing."
echo "Check that they are done in another shell (sorry!)"
read -n1 -r -p "Press any key to continue..." key


echo "Phasing and creating .vcf file"
set -x
if [[ ! -d "$TMP/40_filtered" || "$RECOMPUTE" = true ]] ; then
	mkdir -p "$TMP/40_filtered"
	for bim in "$TMP/30_aligned/"*.bim ; do
		src_prefix=${bim%.bim}
		name=$(basename "$src_prefix")
		dst_prefix="$TMP/40_filtered/$name"
		plink --bfile "$src_prefix" --make-bed \
			--out "$dst_prefix" \
			--geno 0.01 \
			--maf 0.01 \
			--hwe 1e-7

	done
fi


for bed in "$TMP/40_filtered"/*.bim; do
	export prefix="${bed%.bim}"
	export dst="$DST_DIR/$(basename $prefix).phased.vcf"
	if [[ ! -f "$dst" || "$RECOMPUTE" = true ]] ; then
		echo "Phasing $prefix ..."
		sbatch phase.bash
	fi
done

