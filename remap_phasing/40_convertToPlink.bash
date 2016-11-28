#!/bin/bash
set -u
set -e
genome_ref="/apps/data/1000G/release/20130502"
srcd="30_gen"
dstd="40_plink"
mkdir -p ${dstd}


for chr in {1..22}
do
  export ref_chrom=$(echo "$genome_ref/ALL.chr${chr}.phase3_"*".20130502.genotypes.vcf.gz")
  plinkChr=${chr}
  if [ -f "${dstd}/chr_${chr}.bim" ] ; then
    echo "already computed for chromosome $chr. Skipping"
    continue
  fi

  if [ ! -f "$ref_chrom" ] ; then
    echo "unable to find $ref_chrom"
    echo "aborting ..."
    exit 1
  fi

  sbatch -o "${dstd}/chr_${chr}.out" -e "${dstd}/chr_${chr}.err" \
    40_convertToPlink.job \
    "${srcd}/chr_${chr}" \
    "${dstd}/chr_${chr}" \
    $plinkChr
done

