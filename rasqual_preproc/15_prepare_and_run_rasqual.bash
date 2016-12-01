#!/bin/bash
#
# preprocessing prior to running rasqual
# runs rasqual without slurm and parallelism
# should be transferred into a workflow script
#
set -e
set -u

# we need at least R version 3.2
module load R/3.3.1-foss-2015b

# how large area surrounding each gene do we look for SNPs in?
snp_window_size=5e5

function require() {
	bin="$1"
	mod="${2-$bin}"
	command -v "$bin" >/dev/null 2>&1 || module load "$mod"
	if ! command -v "$bin" > /dev/null 2>&1 ; then
		echo > /dev/stderr "Unable to loacate $bin. aborting ..."
		exit 1
	fi
}

function must_exist() {
  if [ ! -f "$1" ] ; then
    echo "input file missing. aborting ..."
    echo "file: $1"
    exit 1
  fi
}

BASE_OUT=post_10
ORIG_VCF=input_data/all.vcf

RAW_CONFIG=30_file_paths.ini
FULL_COUNT_TABLE=/groups/umcg-pub/tmp04/projects/stimulated_gluten_specific_Tcell_clones_TCC23052016/pipelines/no_splice_junctions/results_reverse_complement_paired_fixed/counts.tsv

sdir='.'
R_CACHE=$(readlink -m tmp/R)

must_exist $ORIG_VCF
must_exist $RAW_CONFIG
must_exist $FULL_COUNT_TABLE
require tabix HTSlib
module load scipy # don't know how to check if loaded

mkdir -p $R_CACHE

for tpath in 10_counts/time_* ; do
  tp=$(basename $tpath)
  dstd=$(readlink -m "$BASE_OUT/$tp")
  mkdir -p $dstd

  # preparing to merge sample counts to common table
  sample_map="$dstd/sample_paths.tsv"
  ase_counts="$dstd/ase_counts.tsv"
  if [ ! -f $ase_counts ] ; then
    echo "Storing mapping of sample to CSV count file in $sample_map"
    for csv in $tpath/*.csv ; do 
      name=$(basename $csv .csv)
      echo -e "$name\t$csv"
    done > "$sample_map"

    echo "merging counts and storing results in $ase_counts"
    python $sdir/15_mergeASECounts.py --sample_list $sample_map > $ase_counts
  fi

  sample_geno_map=$dstd/sample_geno_map.tsv
  vcf_counts=$dstd/ase_counts.vcf.gz
  if [ ! -f ${vcf_counts} ] ; then
    echo "Storing mapping of sample name to genotype name in $sample_geno_map"
    # is currently just an identity mapping
    awk '{print $1 "\t" $1}' $sample_map > $sample_geno_map
    echo "Creating count vcf file for timepoint"
    python $sdir/20_vcfAddASE.py \
      --ASEcounts $ase_counts \
      --ASESampleGenotypeMap $sample_geno_map \
      --VCFfile $ORIG_VCF \
      | bgzip -c > $vcf_counts
    tabix -p vcf $vcf_counts
  fi

  tp_config=$dstd/config.ini
  TIME_NAME="gsTCC_${tp}"
  if [ ! -f $tp_config ] ; then
    echo "creating timepoint specific config file: $tp_config"
    GENO_BAM_MAP=$tpath/sample_bam_map.tsv \
      COUNT_TABLE=$FULL_COUNT_TABLE \
      DST_DIR=$dstd \
      CACHE_DIR=$R_CACHE \
      ORIG_VCF=$ORIG_VCF \
      TIME_NAME=$TIME_NAME \
      SNP_CIS_WINDOW=$snp_window_size \
      envsubst < $RAW_CONFIG > $tp_config
    Rscript 30_gen_suppl_tables.R $tp_config
  fi

  #
  # Prepare running Rasqual
  #
  mkdir -p output
  read_counts=$dstd/${TIME_NAME}.expression.bin
  offsets=$dstd/${TIME_NAME}.size_factors_gc.bin
  n=$(wc -l < $sample_geno_map) # < pipe to stdin gives clean numeric output
  outprefix=output/${TIME_NAME}
  rasqual_finished=${outprefix}.is_computed
  geneids=$dstd/geneids.txt
  batch_file=$dstd/batch_spec.txt
  batch_file_prefix=$dstd/geneids_batch_
  gene_metadata=$dstd/snp_counts.tsv
  execute=True
  rasqual_bin=/groups/umcg-wijmenga/tmp04/umcg-elund/apps/rasqual/src/rasqual
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
  if [ ! -f $rasqual_finished ] ; then
  # should run once ber line in batch file through slurm!
   python2 $run_rasqual_py \
    --readCounts $read_counts \
    --offsets $offsets \
    --n $n \
    --vcf $vcf_counts \
    --outprefix $outprefix \
    --geneids $geneids \
    --geneMetadata $gene_metadata \
    --execute $execute \
    --rasqualBin $rasqual_bin \
    < $batch_file
 else
   echo "Skipping rasqual run. $rasqual_finished exists."
 fi
 partial_result_prefix=${outprefix}.$(basename $batch_file_prefix)
 merged_result=${outprefix}.merged.all.txt
 eigenmt_result=${outprefix}.merged.eigenmt.tsv
 if [ ! -f $merged_result ] ; then
   echo "merging results to $merged_result"
   cut -f 1-4,7-9,11-15,17,18,23-25 ${partial_result_prefix}* > $merged_result
 fi
 [ -f $eigenmt_result ] || python rasqualToEigenMT.py --rasqualOut $merged_result > $eigenmt_result
done
