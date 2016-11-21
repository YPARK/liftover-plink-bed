#!/bin/bash
#
# change_plink_reference_genome.bash
#########################
# 
# Script that changes reference genome coordinates for binary PLINK files.
#
# By default, from hg18 to hg19. Update the CHAIN variable to change this.
#
# This script also:
# - excludes SNPs with no new reference position.
set -u
set -e

CHAIN=hg18ToHg19.over.chain.gz
command -v liftOver >/dev/null 2>&1 || { echo >&2 "liftOver not present. do module load ...."; exit 1; }
command -v plink >/dev/null 2>&1 || { echo >&2 "plink not present. do module load ...."; exit 1; }
test -f $CHAIN || wget http://hgdownload.cse.ucsc.edu/goldenPath/hg18/liftOver/$CHAIN
SRC_DIR="$1"
DST_DIR="$2"
mkdir -p "$DST_DIR"

for fam in "$SRC_DIR"/chr*.fam ; do
	NAME=$(basename "$fam" .fam)
	SRC="${fam%.fam}"
	DST="$DST_DIR/$NAME"
	TMPNAME=$DST_DIR/$NAME
	HG18_BED="${TMPNAME}_hg18.bed"
	HG19_BED="${TMPNAME}_hg19.bed"
	HG19_UNMAPPED="${TMPNAME}_hg19_unmapped.bed"
	UPLIST="${TMPNAME}_update_list.txt"

	# convert from binary to textual plink formats and remove
	# SNPs to present in all samples.
	plink --bfile "$SRC" --recode --out "$TMPNAME" > /dev/null
	# SNP name should be enough to track back rest of ID
	awk '{ print "chr" $1, $4, $4 + 1, $2, $3}' OFS='\t' \
		"${TMPNAME}.map" > "$HG18_BED"
	liftOver "$HG18_BED" "$CHAIN" "$HG19_BED" "$HG19_UNMAPPED"
	#Create mapping update list used by Plink
	awk '{print $4, $2}' OFS='\t' "$HG19_BED" > "$UPLIST"
	plink --file $TMPNAME --make-bed --update-map "$UPLIST" --exclude "$HG19_UNMAPPED" \
		--out $DST 
done



