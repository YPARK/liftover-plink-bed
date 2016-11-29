#!/usr/bin/env perl6
#
# Generates slurm jobs that does ASE counting per pair of
# RNA-seq bam file and phased genotype vcf file.
# 	
# Genotype to bam file mapping is written to $outdir/sample_bam_map.tsv

sub MAIN($outdir, $vcf-file='input_data/all.vcf', $min-after-stim = 0, $java-tmp-dir='tmp/java') {
  die("$vcf-file does not exist") if not $vcf-file.IO.f;
  my $conf = read-config('config.ini');
  #die("output directory '$outdir' already exists..") if $outdir.IO.d;
  mkdir $outdir if not $outdir.IO.d;
  mkdir $java-tmp-dir if not $java-tmp-dir.IO.d;

  my @sample-names = read-vcf-samples($vcf-file);
  my %sample-bam = sample-to-bam(@sample-names, $conf<rna-dir>, min-after-stim => $min-after-stim);

  write-sample-bam-mapping %sample-bam, "$outdir/sample_bam_map.tsv";

  for @sample-names -> $sample {
    my $outpath= "$outdir/{$sample}.csv".IO.abspath;
    my %env-vars = genome_ref => $conf<genome-ref>,
		  output_csv => $outpath,
		  input_bam => %sample-bam{$sample},
		  input_vcf => $vcf-file.IO.abspath,
		  java_tmp => $java-tmp-dir.IO.abspath;
    for %env-vars.kv -> $k, $v {
      %*ENV{$k} = $v;
    }
    file-must-exist %*ENV<input_bam>;
    file-must-exist %*ENV<input_vcf>;
    file-must-exist %*ENV<genome_ref>;
    my $shell-cmd = qq:to/END/;
      sbatch \\
	-J "ASE_{$sample}" \\
	-o "{$outpath}.out" \\
	-e "{$outpath}.err" \\
	  {"countASE.job".IO.abspath}
    END
    gen-recompute-script("{$outpath}.compute.bash", $shell-cmd, %env-vars);
    #run "bash", "{$outpath}.compute.bash";
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
  say "Writing sample name to bam file mapping to {$path}";
  my $txt = %m.kv.map(-> $k, $v {"$k\t$v"}).join("\n");
  spurt $path, $txt;
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
      # Bam file name is a (gluten specific) T-Cell Clone
      when /(TCC '-'? \d+) .* t(\d+)/ {
	%names.push($0 => $path.IO.abspath) if $1 == $stimulation-time;
      }
    }
  }
  for %names.kv -> $k, $v is rw {
    if $v.elems > 1 {
      $v = @($v.sort)[0];
    }
  }

  return %names;
}
