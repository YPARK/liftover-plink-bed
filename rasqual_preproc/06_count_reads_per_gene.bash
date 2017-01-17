#!/bin/bash
#SBATCH --nodes=1
#SBATCH --cpus-per-task=20
#SBATCH --time=13:59:59
#SBATCH --mem=40gb
set -u
set -e
BAM_DIR=/groups/umcg-pub/tmp04/projects/stimulated_gluten_specific_Tcell_clones_TCC23052016/pipelines/splice_junctions/results/sortedBam
 GTF=/apps/data/ftp.sanger.ac.uk/pub/gencode/Gencode_human/release_25/GRCh37_mapping/gencode.v25lift37.annotation.gtf
 BAM=$(ls $BAM_DIR/*.bam)
 DST=input_data/gene_counts_fwd_strand.txt


srun featureCounts -T 20 -s 1 -t exon -g gene_id -a "$GTF" -o $DST $BAM
