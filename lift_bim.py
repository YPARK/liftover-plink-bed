import sys
import itertools

def get_name_and_position(f):
    '''
    SNP name and chromosome position.
    Does not preserve chromosome information, but this is already present in bim file.
    '''
    d = {}
    for line in f:
        xs = line.strip().split('\t')
        snp = xs[3]
        pos = xs[1]
        d[snp] = pos
    return d

def to_hg19_bim(ofile, f, snp_positions):
    for bim_line in f:
        xs = bim_line.strip().split()
        snp = xs[1]
        new_pos = snp_positions[snp]
        if new_pos is not None:
            # snp is not on hg19 if new_pos is None
            xs[3] = new_pos
            ofile.write(' '.join(xs))
            ofile.write('\n')

def get_skip_list(f):
    for line in f:
        if not line.startswith('#'):
            snp = line.strip().split()[-1]
            yield snp

if __name__ == '__main__':
    if len(sys.argv) < 4:
        print('Three required arguments: hg18_bim_file hg19_bed_file hg18_unmapped [output_file]')
        print('Outputs a hg19_bim_file')
        sys.exit(1)
    bim_path = sys.argv[1]
    hg19_bed_file = sys.argv[2]
    hg18_unmapped = sys.argv[3]
    if len(sys.argv) == 5:
        outfile = open(sys.argv[4], 'w')
    else:
        outfile = sys.stdout

    fpos = open(hg19_bed_file)
    snp_pos = get_name_and_position(fpos)
    with open(hg18_unmapped) as f:
        for skip_snp in get_skip_list(f):
            snp_pos[skip_snp] = None #'-1' #None
    fbim = open(bim_path)
    to_hg19_bim(outfile, fbim, snp_pos)
