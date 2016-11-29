#!/bin/bash
#
# preprocessing for 15_mergeASCounts.py
# Creates a mapping from sample_name to RNA_ASE_COUNTS.csv file
# TODO general cleanup
#
set -e
set -u

# we need at least R version 3.2
module load R/3.3.1-foss-2015b

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
  vcf_counts=$dstd/ase_counts.vcf
  if [ ! -f $vcf_counts ] ; then
    echo "Storing mapping of sample name to genotype name in $sample_geno_map"
    # is currently just an identity mapping
    awk '{print $1 "\t" $1}' $sample_map > $sample_geno_map
    echo "Creating count vcf file for timepoint"
    python $sdir/20_vcfAddASE.py > $vcf_counts \
      --ASEcounts $ase_counts \
      --ASESampleGenotypeMap $sample_geno_map \
      --VCFfile $ORIG_VCF
  fi

  tp_config=$dstd/config.ini
  if [ ! -f $tp_config ] ; then
    echo "creating timepoint specific config file: $tp_config"
    GENO_BAM_MAP=$tpath/sample_bam_map.tsv \
      COUNT_TABLE=$FULL_COUNT_TABLE \
      DST_DIR=$dstd \
      CACHE_DIR=$R_CACHE \
      ORIG_VCF=$ORIG_VCF \
      TIME_NAME="gsTCC_${tp}" \
      envsubst < $RAW_CONFIG > $tp_config
    Rscript 30_gen_suppl_tables.R $tp_config
  fi
done
