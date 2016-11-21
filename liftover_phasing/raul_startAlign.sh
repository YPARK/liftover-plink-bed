#!/bin/bash

set -u
set -e

inputFolder="$1"
outputFolder="$2"

refFolder="/groups/umcg-wijmenga/tmp04/umcg-vmatzaraki/1000GenomesRef"

mkdir -p ${outputFolder}

for chr in {1..22}
do
    ### building the jobs   
	sbatch \
	-J "align_plink_chr${chr}" \
	-o "${outputFolder}/chr${chr}.out" \
	-e "${outputFolder}/chr${chr}.err" \
	-v raul_align.job \
	 "${inputFolder}/chr${chr}" \
	 "${outputFolder}/chr${chr}" \
	 "${refFolder}/ALL.chr${chr}.phase3_shapeit2_mvncall_integrated_v5a.20130502.genotypes.vcf.gz"
	 # 1- plink format file . depending on chr. "${inputFolder}/chr${chr}" 
	 # 2- path to folder to store the alligned files . depending on chr. "${outputFolder}/chr${chr}" 
	 # 3- Reference data from 100 Genomes in this case. depending on chr. "${refFolder}/chr${chr}.vcf.gz"
    # Orginal code from Patrick 
    #qsub -N "${cohort}_plink_${chr}" -o "${outputFolder}/chr${chr}.out" -e "${outputFolder}/chr${chr}.err" \
    #    -v input="${inputFolder}/chr${chr}",output="${outputFolder}/chr${chr}",ref="${refFolder}/chr${chr}.vcf.gz", align.job
   
done

