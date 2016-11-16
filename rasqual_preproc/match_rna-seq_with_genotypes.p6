#!/usr/bin/env perl6
use v6;

#
# Combines RNA-seq data matching genotype data.
# My very first perl 6 script, so this is probably not the best way to do it.
#


sub read-filenames($bam-dir) {
    $bam-dir.IO.dir(test => / '.' bam $/).map(*.Str);
}

sub id_to_bamfile(@file-paths, :$stimulation-time=0) returns Hash {
    my %names;
    for @file-paths {
	when /(TCC '-'? \d+) .* t(\d+)/ {
	    if $1 == $stimulation-time {
		%names.push($0 => $_);
	    }
	}
    }

    say "There are multiple experiments performed for some samples.";
    say "We only select the first sample by default. The samples could also be merged? But this wont matter much.";
    say "The multi matching samples are:";
    for %names.kv -> $k, $v is rw {
	if $v.elems > 1 {
	    say $k;
	    for @($v) {
		say "\t$_";
	    }
	    $v = @($v)[0];
	}
    }
    say '';
    for %names.kv -> $k, $v {
	say "$k: $v";
    }
    return %names;
}

sub genotype-ids($path) {
    # Initial genotype processing had a two column list of
    # oldnames and newnames, and here I just extract the new names.
    # This is just confusing, so I think it is better to just supply the new names
    #$path.IO.lines.map(*.split(',')[1]);
    $path.IO.lines;
}

multi MAIN($genotype-path, $bam-dir) {
    my @genotype-ids = genotype-ids $genotype-path;
    my @files = read-filenames $bam-dir;
    my %paths = id_to_bamfile(@files, stimulation-time => 0);

    my @common-ids = (@genotype-ids (&) %paths.keys).keys;

    say "We have rna-seq data for {%paths.elems} people.";
    say "We have genotype data for {@genotype-ids.elems} people.";
    say "Of those, {@common-ids.elems} overlap.";

    for @common-ids -> $name {
	my $path = %paths{$name}.IO.abspath;
	say "$name:\t$path";
    }
}
