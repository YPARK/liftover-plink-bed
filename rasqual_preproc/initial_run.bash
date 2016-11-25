set -u
set -e

read_counts=30_out/gsTCC_time0.expression.bin
offsets=30_out/gsTCC_time0.size_factors_gc.bin
n=21
vcf=output/all.counts.vcf.bgz
outprefix=output/gsTCC_time0
geneids=30_out/geneids.txt
batch_file=30_out/batch_spec.txt
batch_file_prefix=30_out/geneids_batch_
gene_metadata=30_out/snp_counts.tsv
execute=True
rasqual_bin=/home/el/code/liftover-plink-bed/rasqual/src/rasqual
run_rasqual_py=runRasqual.py

[ -f $geneids ] || cut -f 1 ${read_counts%.bin}.txt > $geneids

if [ ! -f $batch_file ] ; then
  split -l 5000 $geneids $batch_file_prefix
  for x in ${batch_file_prefix}* ; do
    echo -ne "$(basename $x)\t" >> $batch_file
    tr '\n' ',' < $x >> $batch_file
    echo >> $batch_file
  done
fi

python2 $run_rasqual_py \
  --readCounts $read_counts \
  --offsets $offsets \
  --n $n \
  --vcf $vcf \
  --outprefix $outprefix \
  --geneids $geneids \
  --geneMetadata $gene_metadata \
  --execute $execute \
  --rasqualBin $rasqual_bin \
  < $batch_file

