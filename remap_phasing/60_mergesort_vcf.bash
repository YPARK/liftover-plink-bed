#!/usr/bin/env bash
set -u
set -e

module load picard
module load VCFtools

refVcfDict='/groups/umcg-wijmenga/tmp04/resources/b37/indices/human_g1k_v37.dict'
vcfs=50_phased/chr_*.phased.aligned.vcf

vcf-concat $vcfs > merged_unsorted.vcf
java -jar ${EBROOTPICARD}/picard.jar SortVcf \
  I=merged_unsorted.vcf \
  O="gsTCC.IChip.all.vcf" \
  SEQUENCE_DICTIONARY="$refVcfDict"
rm -f merged_unsorted.vcf
