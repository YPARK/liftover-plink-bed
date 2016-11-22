# Notes

This is the first time I connect genotype and RNA-seq data.
I decided to note down observations that puzzled me, so I don't forget and have
to spend time resolving the same issue multiple times over.

## Why do I get so few and variable number of SNPs per GATK ASEReadCounter call?
SNPs without reads are skipped. The number of SNPs without covereage greatly depends
on the read depth and that is why we have this discrepancy.

## Why do only see reads for the reference allele for the majority of SNPs?
Because most samples are homozygous for (almost) any reference SNP.
