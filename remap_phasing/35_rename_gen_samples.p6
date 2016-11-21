#!/usr/bin/env perl6

sub MAIN($keep-csv-path, $gen-dir, $backup-postfix='.old') {
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
  my $fh = $sample-list-path, :w;
  $fh.say("{$_}\t{$_}") for %to-new.values;
  $fh.close;
  say "Wrote sample list to $sample-list-path";
}

sub read-sample-map($path) {
  %($path.IO.lines>>.split(',').flat);
}

