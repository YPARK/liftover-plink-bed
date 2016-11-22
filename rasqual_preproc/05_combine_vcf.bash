#!/bin/bash
set -u
set -e

module load picard
module load VCFtools

ref_dict=/apps/data/ftp.broadinstitute.org/bundle/2.8/b37/human_g1k_v37.dict
mkdir -p input_data

vcf-concat ../remap_phasing/50_phased/*.vcf > input_data/all_unsorted.vcf
java -jar ${EBROOTPICARD}/picard.jar SortVcf I="input_data/all_unsorted.vcf" O="input_data/all.vcf" SEQUENCE_DICTIONARY="$ref_dict"

