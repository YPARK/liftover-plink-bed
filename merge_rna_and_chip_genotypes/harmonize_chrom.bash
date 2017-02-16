#!/usr/bin/env bash
set -u
set -e

CHROM=22
SRC_RNA="input_data/rna_vcf/gsTCC.chr${CHROM}.gg.vcf.gz"
SRC_CHIP="input_data/chip_plink/chr_${CHROM}"
REF_CHROM="/groups/umcg-wijmenga/tmp04/resources/b37/variants/1000G_Phase3/ALL.chr${CHROM}.phase3_shapeit2_mvncall_integrated_v5a.20130502.genotypes.vcf.gz"
DST_DIR=out/harmonized_data
mkdir -p $DST_DIR
DST_RNA=$DST_DIR/rna_chr${CHROM}
DST_CHIP=$DST_DIR/chip_chr${CHROM}

[ -f $SRC_RNA ] || (echo "Missing $SRC_RNA" ; exit 1)
[ -f ${SRC_CHIP}.bed ] || (echo "Missing $SRC_CHIP" ; exit 1)
[ -f $REF_CHROM ] || (echo "Missing $REF_CHROM" ; exit 1)

module load GenotypeHarmonizer

GenotypeHarmonizer.sh \
    --input $SRC_RNA \
    --inputType VCF \
    --output $DST_RNA \
    --outputType PLINK_BED \
    -r "$REF_CHROM" \
    --refType VCF \
    --update-id \
    --inputProb 0.7 \
    --update-reference-allele
