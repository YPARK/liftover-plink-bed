'''
Reads a .fam file and name mapping .csv file.
Outputs new .fam file with translated names according to csv file as well
as a file with a list of the new sample names.



python filter_rename_samples.py rename_list.csv file.fam <output_prefix>

rename_list.csv format (no header):
    - old_name, new_name

This creates two files:
    - <output_prefix>.fam
    - <output_prefix>.samples

Updates file.fam inplace, but stores backup in file.fam_old
'''
import csv
import os
import sys
import shutil

def immunochip_to_patient_name(csvfile):
    with open(csvfile) as f:
        d = {}
        for row in csv.reader(f):
            ichip_name = row[0]
            patient_id= row[1]
            d[ichip_name] = patient_id 
    return d
        
def parse_fam_file(f):
    for line in f:
        yield line.strip().split()

def rename_entry(x, d):
    y = list(x)
    old_name = x[0]
    new_name = d.get(old_name, old_name)
    y[0] = new_name
    y[1] = new_name
    return y

if __name__ == '__main__':
    if len(sys.argv) != 4:
        print('Program has 3 required arguments.')
        print('python filter_rename_samples.py rename_list.csv file.fam <output_prefix>')
        print()
        print('You supplied %d: %s' % (len(sys.argv[1:]),  ' '.join(sys.argv[1:])))

    name_map = immunochip_to_patient_name(sys.argv[1])
    out_fam = sys.argv[3] + '.fam'
    out_samples = sys.argv[3] + '.samples'
    
    with open(sys.argv[2]) as f:
        lines = f.readlines()

    with open(out_fam, 'w') as f:
        for xs in parse_fam_file(lines):
            xs = rename_entry(xs, name_map)
            f.write(' '.join(xs))
            f.write('\n')

    with open(out_samples, 'w') as f:
        for sample in name_map.values():
            f.write(sample)
            f.write('\t')
            f.write(sample)
            f.write('\n')

