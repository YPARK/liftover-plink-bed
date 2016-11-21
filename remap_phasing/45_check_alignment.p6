#!/usr/bin/env perl6
use v6;

# Print number of SNPs lost during processing.

sub MAIN {
  my @stage-order = 'intensity', 'gen', 'plink_40', 'plink_41', 'plink_42', 'vcf';
    my %stages =  
      intensity => &SNPs-in-plink-file,
      gen => &SNPs-in-plink-file,
      plink_40 => &SNPs-in-plink-file,
      plink_41 => &SNPs-in-plink-file.assuming(dir-name=>'41_subset'),
      plink_42 => &SNPs-in-plink-file.assuming(dir-name=>'42_plink'),
      vcf => &SNPs-in-vcf-file;
	      
	  
  for flat 1..22 -> $chr {
    my %counts;

    print "chr=$chr\t";

    for @stage-order -> $name {
      %counts{$name} = %stages{$name}($chr);
      print "$name={%counts{$name}}\t";
    }
    my $tot-count = %counts<intensity>;
    for @stage-order[1..*] -> $name {
      print "diff_$name={$tot-count - %counts{$name}}\t";
    }
    say "";
  }
}

sub SNPs-in-vcf-file ($chr-number, $dir-name='50_phased') {
  "$dir-name/chr_{$chr-number}.phased.vcf".IO.lines.grep({! /^\#/}).elems;
}

sub SNPs-in-intensity-file($chr-number, $dir-name='15_common_intensities') {
  "$dir-name/chr_{$chr-number}_intensities.tsv".IO.lines.elems - 1;
}

sub SNPs-in-gen-file($chr-number, $dir-name='30_gen') {
  "$dir-name/chr_{$chr-number}".IO.lines.elems;
}

sub SNPs-in-plink-file($chr-number, :$dir-name='40_plink') {
  "$dir-name/chr_{$chr-number}.bim".IO.lines.elems;
}

