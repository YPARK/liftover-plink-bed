#!/bin/bash

set -u
set -e

TMP=tmp_hg18_lift
BIM_HG18="$1"
BIM_HG19="$2"
NAME=$(basename "$BIM_HG18" .bim)
HG18_BED="$TMP/${NAME}_hg18.bed"
HG19_BED="$TMP/${NAME}_hg19.bed"
HG18_UNMAPPED="$TMP/${NAME}_unmapped.bed"
CHAIN=hg18ToHg19.over.chain.gz

mkdir -p "$TMP"
command -v liftOver >/dev/null 2>&1 || { echo >&2 "liftOver not present. do module load ...."; exit 1; }
test -f $CHAIN || wget http://hgdownload.cse.ucsc.edu/goldenPath/hg18/liftOver/$CHAIN

echo "liftover $BIM_HG18"
# SNP name should be enough to track back rest of ID
awk '{ print "chr" $1 "\t" $4 "\t" $4 + 1 "\t" $2 }' "$BIM_HG18" > "$HG18_BED"
liftOver "$HG18_BED" "$CHAIN" "$HG19_BED" "$HG18_UNMAPPED" > /dev/null 2>&1

python lift_bim.py "$BIM_HG18" "$HG19_BED" "$HG18_UNMAPPED" "$BIM_HG19"

#rm -fr "$TMP"
