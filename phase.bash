#!/bin/bash
#SBATCH --time=00:05:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=6000
#SBATCH --output=logs/align_%j.txt

#prefix="${bed%.bed}"
chr=$(basename "$prefix")
echo "Phasing $prefix ..."
srun shapeit --input-bed "$prefix" \
	--input-map genetic_map_b37/genetic_map_${chr}_combined_b37.txt \
	--thread 4
	--output-max "${prefix}.phased.haps" "${prefix}.phased.sample" \
	--output-log "${prefix}.phased.log"
srun shapeit -convert \
	--input-haps "${prefix}.phased" \
	--output-vcf "${prefix}.phased.vcf" \
	--output-log "${prefix}.phased.vcf.log"
