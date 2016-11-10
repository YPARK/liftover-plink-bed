# process-plink-bed
Pipeline that:
	1. Filters subset of genotype samples
	2. Renames said subset
	3. Converts genome coordinates to wanted reference genome
	4. Phases genotypes and creates .vcf files

I is quite specific to a particular use case, but it is trivial to generalize the 
functionality if this is ever needed.

# Sub tools

## filter-rename-samples
Rename a subset of samples, remove others.

Accepts a .csv file with *oldname*, *newname* columns.
Renames these samples and filters every other.
Creates a new directory for output.

### Example input
```
$ ls plink_hg18/chr_15*
plink_hg18/chr_15.bed plink_hg18/chr_15.bim  plink_hg18/chr_15.fam

$ head -2 keep.csv
oldname1, newname1
oldname2, newname2
```

### Example Run
```
bash filter_rename_samples.bash keep.csv plink_hg18 plink_hg18_subset
```

## change-plink-reference-genome
Change reference genome for binary PLINK files.

By default, from hg18 to hg19. 
Update the CHAIN variable in *change_plink_reference_genome.bash* to
change this.

### Example Input
```
$ ls plink_hg18/chr_15*
plink_hg18/chr_15.bed plink_hg18/chr_15.bim  plink_hg18/chr_15.fam
```

### Example Run
```
bash change_plink_reference_genome.bash plink_hg18/chr_15 plink_hg19/chr15
```

