#!/usr/bin/env perl6
#
# I has some problems with disk quota terminating my jobs in interesting ways.
# This quick script ensures md5sums for two replicate runs are identical.
#

sub MAIN($dir1, $dir2) {
  my %vcf1 = get-vcf-map $dir1;
  my %vcf2 = get-vcf-map $dir2;

  my @no-intersect = (%vcf1 (^) %vcf2).keys;
  my @has-intersect = (%vcf1 (&) %vcf2).keys;

  say "{@no-intersect.elems} files are not intersecting";
  say "{@has-intersect.elems} files are intersecting";
  
  my @trouble-items = @has-intersect.grep: { 
    compute-md5(%vcf1{$_}) ne compute-md5(%vcf2{$_})
  };
  if @trouble-items.elems > 0 {
    say "There are {@trouble-items.elems} problematic items.";
    say "These are: {@trouble-items}";
  } else {
    say "All corresponding files are identical":
  }
}

sub compute-md5 ($path) {
  qqx/md5sum $path/.lines[0].words[0];
}

sub get-vcf-map ($vcf-dir) {
  my @paths = $vcf-dir.IO.dir(test => / '.' vcf $/);
  my @names = @paths>>.basename;
  my %d = (@names Z @paths).flat;
  return %d;
}
