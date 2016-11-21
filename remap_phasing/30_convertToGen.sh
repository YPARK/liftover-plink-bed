#!/bin/bash
set -u
set -e

srcd=20_opticall
dstd=30_gen
mkdir -p "$dstd"
for input in "$srcd"/*.probs ; do
  chr=$(basename "$input") 
  chr=${chr#chr_}
  chr=${chr%.probs}
  output="$dstd/chr_${chr}"
  sampleFile="${output}.sample"
  echo -e "$chr\t$input\t$output"
  awk -v chr=${chr} -v sampleFile="${sampleFile}" \
    -f 30_process.awk "${input}" > "${output}"
done


