#!/usr/bin/env perl6

# $keep-csv-path: file with samples you want to keep, with a second column for the new name.
# $gen-dir: file containing files in genotype file format for Oxford statistical genetics tools,
sub MAIN($keep-csv-path='input_data/keep_list.csv', $gen-dir='30_gen', $backup-postfix='.old') {
  my %to-new = read-sample-map $keep-csv-path;
  my @sample-files = $gen-dir.IO.dir(test => / '.' sample $/);
  for @sample-files -> $dst-path { 
    my $src-path = $dst-path ~ $backup-postfix;
    if $src-path.IO.f {
      say "skipping: $src-path already exists..";
      next;
    }
    $dst-path.move($src-path);
    my $fh = open $dst-path, :w;
    for $src-path.IO.lines {
      my ($id1, $id2, $missing) = $_.split(' ');
      if $id1 ~~ %to-new {
	$id1 = $id2 = %to-new{$id1};
      }
      $fh.say("$id1 $id2 $missing");
    }
    $fh.close;
    say "converted $dst-path";
  }

  my $sample-list-path = "$gen-dir/relevant-samples.txt";
  say "Writing mapping to $sample-list-path";
  say "In total {%to-new.elems} values";
  my $fh = open $sample-list-path, :w;
  for %to-new.values {
    $fh.say("$_\t$_");
  }
  $fh.close;
  say "Wrote sample list to $sample-list-path";
}

sub read-sample-map($path) returns Hash {
  %($path.IO.lines>>.split(',').flat);
}

