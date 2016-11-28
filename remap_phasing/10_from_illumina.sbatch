#!/bin/bash
#SBATCH --mem=30gb
#SBATCH --cpus-per-task=2
#SBATCH --time=23:59:59
#SBATCH -V


# input is just a symbolic link. get full path

src="$1"
dstd="$2"
mkdir -p "$dstd"
java  \
  -Xmx8g -Xms8g \
   -XX:ParallelGCThreads=1 \
   -Djava.io.tmpdir="$JAVA_TMP" \
  -jar input_data/GenomeStudioExportToOptiCall-1.3-SNAPSHOT-jar-with-dependencies.jar \
    -r "$src" \
    -o "$dstd" \
    -p ImmunoProbes_gappedPassedProbes.txt \
    -ed

