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
# - excludes SNPs not present in all samples

set -u
set -e

TMP=.tmp_lift
SRC="$1"	# prefix path
DST="$2"	# prefix path
if [ ! -f "${SRC}.bim" ] ; then
	echo >&2 "incorrect prefix path. ${SRC}.bim does not exist"
	exit 1
fi
if [ ! -d "$(dirname $DST)" ] ; then
	mkdir -p "$(dirname $DST)"
fi
NAME=$(basename "$SRC")
TMPNAME=$TMP/$NAME
HG18_BED="${TMPNAME}_hg18.bed"
HG19_BED="${TMPNAME}_hg19.bed"
CHAIN=hg18ToHg19.over.chain.gz

echo "liftover $SRC"
mkdir -p "$TMP"
command -v liftOver >/dev/null 2>&1 || { echo >&2 "liftOver not present. do module load ...."; exit 1; }
command -v plink >/dev/null 2>&1 || { echo >&2 "plink not present. do module load ...."; exit 1; }
test -f $CHAIN || wget http://hgdownload.cse.ucsc.edu/goldenPath/hg18/liftOver/$CHAIN

# convert from binary to textual plink formats and remove
# SNPs to present in all samples.
plink --bfile "$SRC" --geno 0 --recode --out "$TMPNAME"
# SNP name should be enough to track back rest of ID
awk '{ print "chr" $1 "\t" $4 "\t" $4 + 1 "\t" $2 "\t" $3}' \
	"${TMPNAME}.map" > "$HG18_BED"
liftOver "$HG18_BED" "$CHAIN" "$HG19_BED" /dev/null > /dev/null 2>&1

python update_map_positions.py "${TMPNAME}.map" "$HG19_BED" "${TMPNAME}.exclude"
plink --file $TMPNAME --make-bed --exclude "${TMPNAME}.exclude" --out $DST
rm -fr "$TMP"

# TODO: add this to other script?
# shapeit --input-bed plink_hg19/chr17 --input-map genetic_map_b37/genetic_map_chr17_combined_b37.txt --output-max test_phased.haps test_phased.sample

