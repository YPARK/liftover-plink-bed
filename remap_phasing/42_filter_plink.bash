#!/bin/bash

set -u
set -e

module load plink

SRC_DIR=41_subset
DST_DIR="42_plink"
RECOMPUTE=true
echo "Writing to $DST_DIR"

if [[ ! -d "$DST_DIR" || "$RECOMPUTE" = true ]] ; then
  mkdir -p "$DST_DIR"
  for chr in {1..22} ; do
    src_prefix=$SRC_DIR/chr_${chr}
    echo "processing $src_prefix"
    name=$(basename "$src_prefix")
    dst_prefix="$DST_DIR/$name"
    plink --bfile "$src_prefix" --make-bed \
      --out "$dst_prefix" \
      --geno 0.01 \
      --hwe 1e-7 | tee "${dst_prefix}.full_log"

    plink --bfile "$dst_prefix" --freq counts --out "$dst_prefix"
  done
fi

