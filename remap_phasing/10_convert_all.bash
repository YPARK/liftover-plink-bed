#!/bin/bash
srcd=0_illumina_intensities
dstd=10_ichip_lldeep/individual
export JAVA_TMP=tmp/java
mkdir -p $dstd $JAVA_TMP
for src in "$srcd"/*.txt ; do
  name=$(basename "$src" .txt)
  dst="$dstd/$name"
  sbatch  \
    -J "ichip_convert_$name" -o "${dst}.out" -e "${dst}.err" \
    10_from_illumina.sbatch \
    "$(readlink -m $src)" "$dst"
done

echo "run 10_combine_all.bash when the spawned jobs are finished"
