#!/bin/bash

set -u
set -e

TMP=tmp_hg18_lift
SRC="$1"	# prefix path
DST="$2"	# prefix path
if ! -f "${SRC}.bim" ; then
	echo >&2 "incorrect prefix path. ${SRC}.bim does not exist"
	exit 1
fi
NAME=$(basename "$SRC")
TMPNAME=$TMP/$NAME
HG18_BED="${TMPNAME}_hg18.bed"
HG19_BED="${TMPNAME}_hg19.bed"
HG19_UNMAPPED="$TMP/${NAME}_unmapped.bed"
CHAIN=hg18ToHg19.over.chain.gz

mkdir -p "$TMP"
command -v liftOver >/dev/null 2>&1 || { echo >&2 "liftOver not present. do module load ...."; exit 1; }
test -f $CHAIN || wget http://hgdownload.cse.ucsc.edu/goldenPath/hg18/liftOver/$CHAIN

# convert from binary to textual plink formats and remove
# SNPs to present in all samples.
plink --bfile plink_hg18/chr_22 --geno 0 --recode --out tmp/chr22
echo "liftover $BIM_HG18"
# SNP name should be enough to track back rest of ID
awk '{ print "chr" "$1 "\t" $4 "\t" $4 + 1 "\t" $2 "\t" $3}' \
	"${TMPNAME}.map" > "$HG18_BED"
liftOver "$HG18_BED" "$CHAIN" "$HG19_BED" "$HG19_UNMAPPED" > /dev/null 2>&1

python update_map_positions.py "${TMPNAME}.map" "$HG19_BED" 

#rm -fr "$TMP"
