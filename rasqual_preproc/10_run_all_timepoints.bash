#!/bin/bash
# Add non-determistic sample order

module load VCFtools
set -x
set -u
set -e
for x in 0 10 30 180 ; do 
  perl6 ./10_run_ASE_count.p6 10_counts/time_$x input_data/all.vcf $x
done


