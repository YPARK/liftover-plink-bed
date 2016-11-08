'''
update_map_positions.py
#######################
See https://www.cog-genomics.org/plink2/formats#map
    http://pngu.mgh.harvard.edu/~purcell/plink/dataman.shtml#exclude

Reads map file and liftover bedfiles (e.g. hg18_map and hg19_bed):
    Updates every position in hg18_map with:
        1. position in bed file - if bedfile has entry
        2. sets position to -1 otherwise

NOTE: THIS SCRIPT OVERWRITES THE INPUT MAP FILE
'''
import sys

mapfile = sys.argv[1]
bedfile = sys.argv[2]
exclude_out = sys.argv[3]

snp_pos = {}
with open(bedfile) as f:
    for line in f:
        xs = line.strip().split('\t')
        snp_pos[xs[3]] = xs[1]

with open(mapfile) as f:
    map_lines = f.readlines()

exclude_list = []
with open(mapfile, 'w') as f:
    for line in map_lines:
        xs = line.strip().split()
        name = xs[1]
        if name in snp_pos:
           # we have an update position
           xs[3] = snp_pos[name]
        else:
            # unable to liftover SNP, mark with -1
            xs[3] = -1
            exclude_list.append(name)
        f.write('\t'.join(xs) + '\n')

with open(exclude_out, 'w') as f:
    for x in exclude_list:
        f.write(x + '\n')

        
