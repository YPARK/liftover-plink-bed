# liftover-plink-bed
Change reference genome for binary PLINK files.

By default, from hg18 to hg19. 
Update the CHAIN variable in *change_plink_reference_genome.bash* to
change this.

## Example
```
$ ls plink_hg18/chr_15*
plink_hg18/chr_15.bed plink_hg18/chr_15.bim  plink_hg18/chr_15.fam
```

```
bash change_plink_reference_genome.bash plink_hg18/chr_15 plink_hg19/chr15
```

