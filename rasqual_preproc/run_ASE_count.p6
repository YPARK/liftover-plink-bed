#!/usr/bin/env perl6

# TODO:
#
# Ok to do everything in one go, but:
#  1. I absolutely need to write down the bam file used per sample name.
#  2. I should therefore also process every VCF file in one go
# 	
# 

sub MAIN($outdir, $min-after-stim = 0, $java-tmp-dir='tmp/java') {
  my $conf = read-config('config.ini');
  #die("output directory '$outdir' already exists..") if $outdir.IO.d;
  mkdir $outdir;

  if not $java-tmp-dir.IO.d {
    mkdir $java-tmp-dir;
  }

  my @vcf-files = locate-vcf-files $conf<vcf-dir>;
  # all VCF files must have the same set of samples.
  # I don't check this ...
  my @sample-names = read-vcf-samples(@vcf-files[0]);
  my %sample-bam = sample-to-bam(@sample-names, $conf<rna-dir>, min-after-stim => $min-after-stim);

  write-sample-bam-mapping %sample-bam, "$outdir/sample_bam_map.tsv";

  for @vcf-files -> $vcf-path {
    my $chr = extract-chr($vcf-path.IO.basename);
    for @sample-names -> $sample {
      my $outpath= "$outdir/{$chr}_{$sample}.csv";
      my %env-vars = genome_ref => $conf<genome-ref>,
		    output_csv => $outpath,
		    input_bam => %sample-bam{$sample},
		    input_vcf => $vcf-path,
		    java_tmp => $java-tmp-dir;
      for %env-vars.kv -> $k, $v {
	%*ENV{$k} = $v;
      }
      file-must-exist %*ENV<input_bam>;
      file-must-exist %*ENV<input_vcf>;
      file-must-exist %*ENV<genome_ref>;
      my $shell-cmd = qq:to/END/;
	sbatch \\
	  -J "ASE_{$chr}_{$sample}" \\
	  -o "{$outpath}.out" \\
	  -e "{$outpath}.err" \\
	    {"countASE.job".IO.abspath}
      END
      gen-recompute-script("{$outpath}.rerun.bash", $shell-cmd, %env-vars);
    }
  }
}

sub gen-recompute-script($outp, $shell-cmd, %env-vars) {
  my @xs = %env-vars.keys.map({ "export {$_}={%env-vars{$_}}" });
  spurt $outp, @xs.push($shell-cmd).join("\n");
}

sub file-must-exist(Str $path) {
  die("Unable to locate $path") if not $path.IO.f;
}

sub write-sample-bam-mapping(%m, $path) {
  say "Writing sample name to bam file mapping to {$path}.";
  my $txt = %m.kv.map(-> $k, $v {"$k\t$v"}).join("\n");
  spurt $path, $txt;
}

sub locate-vcf-files($vcf-dir) {
    $vcf-dir.IO.dir(test => / '.' vcf $/).map(*.Str);
}

sub extract-chr($filename) {
  ~$0 if $filename ~~ /chr_(\d+)/ or die("Unable to extract chrom name from $filename");
}

sub read-vcf-samples($vcf-path) {
  # vcftools must be installed (module load VCFtools)
  # Order of sample names must be consistent throughout the analysis
  my @res = qq:x/ vcf-query -l {$vcf-path} /.lines or die('Problems running vcf-query.');
  return @res;
}
sub read-config($config-path) {
  use Config::Simple;
  my $conf = Config::Simple.read($config-path) :f('ini');
  return $conf<config>;
}


# my @genotype-ids = genotype-ids $genotype-path;
#| locates bam files corresponding to given samples
sub sample-to-bam(@sample-names, $bam-dir, :$min-after-stim=0) {
    my @files = read-filenames $bam-dir;
    my %paths = id-to-bamfile(@files, stimulation-time => $min-after-stim);
    my @common-ids = (@sample-names (&) %paths.keys).keys;
    if @common-ids.elems < 1|@sample-names.elems {
      say @sample-names;
      say @common-ids;
      die(
	qq:to/EOF/;
	#files: {@files.elems}
	#paths: {%paths.elems}
	sample-names: {@sample-names}
	bam-names:    {%paths.keys}
	Number of samples: {@sample-names.elems}
	Unable to find bam for all vcf samples [{@common-ids.elems} < {@sample-names.elems}]
	EOF
    );
    }
    my %d = @common-ids.map({$_ => %paths{$_}});
    return %d;
}


sub read-filenames($bam-dir) {
    $bam-dir.IO.dir(test => / '.' bam $/).map(*.Str);
}

sub id-to-bamfile(@file-paths, :$stimulation-time=0) returns Hash {
  my %names;
  for @file-paths -> $path {
    given $path.IO.basename {
      when /(TCC '-'? \d+) .* t(\d+)/ {
	%names.push($0 => $path.IO.abspath) if $1 == $stimulation-time;
      }
    }
  }
  for %names.kv -> $k, $v is rw {
    if $v.elems > 1 {
      $v = @($v)[0];
    }
  }

  return %names;
}
