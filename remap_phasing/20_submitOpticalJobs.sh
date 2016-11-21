set -u
set -e

srcd=15_common_intensities
dstd=20_opticall
mkdir -p $dstd
for src in "$srcd"/*.tsv; do
  chr=$(basename "$src")
  chr=${chr#chr_}
  chr=${chr%_*}
  dst="$dstd/chr_$chr"
  [[ -f "${dst}.calls" ]] || sbatch -J "opticall_$chr" -o "${dst}.out" -e "${dst}.err" \
    20_opticall.job ${src} ${dst} ${chr}
done

