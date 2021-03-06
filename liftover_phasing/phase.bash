#!/bin/bash
#SBATCH --time=00:05:00
#SBATCH --mem=600
#SBATCH --output=logs/phase_%j.txt

set -u
set -e
#prefix="${bed%.bed}"
chr=$(basename "$prefix")
dst_dir=$(dirname "$dst")
name=$(basename "$prefix")
echo "Phasing $prefix ..."
srun shapeit --input-bed "$prefix" \
	--input-map genetic_map_b37/genetic_map_${chr}_combined_b37.txt \
	--output-max "${prefix}.phased.haps" "${prefix}.phased.sample" \
	--output-log "${prefix}.phased.log"
srun shapeit -convert \
	--input-haps "${prefix}.phased" \
	--output-vcf "${prefix}.phased.vcf" \
	--output-log "${prefix}.phased.vcf.log"

mkdir -p "$dst_dir"
# bgzip is part of tabix
#bgzip -c "${prefix}.phased.vcf" > "$dst/${name}.phased.vcf.bgz" 
#tabix -p vcf "$dst/${name}.phased.vcf.bgz"
cp "${prefix}.phased.vcf" "$dst" 
