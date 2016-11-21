use Config::Simple;

sub MAIN ($sample-to-bam-file){
  my $conf = read-config('config.ini');
  my %sample-bam = parse-bam-map $sample-to-bam-file;
  my %to-vcf = parse-vcf-map $conf<vcf-dir>;
  my @failed-runs = find-failed-jobs $sample-to-bam-file.IO.dirname;
  my $tmp-dir = "tmp_ase_compute";
  mkdir $tmp-dir if not $tmp-dir.IO.d;

  for @failed-runs -> $log {
  if ($log.IO.basename ~~ / ^ ( \d+ ) _ (.+) '.csv.err'  / ) {
    my $chr = ~$0;
    my $sample  = ~$1;

    my $outpath= "{$log.IO.dirname}/{$chr}_{$sample}.csv";
    my %env-vars = genome_ref => $conf<genome-ref>,
		  output_csv => $outpath,
		  input_bam => %sample-bam{$sample},
		  input_vcf => %to-vcf{$chr},
		  tmp_ase => $tmp-dir;

    my $shell-cmd = qq:to/END/;
      sbatch \\
	-J "ASE_{$chr}_{$sample}" \\
	-o "{$outpath}.out" \\
	-e "{$outpath}.err" \\
	countASE.job 
    END
    gen-recompute-script("{$outpath}.rerun.bash", $shell-cmd, %env-vars);
  } else {
    die ("unable to match $log")
  }
  }
}

sub gen-recompute-script($outp, $shell-cmd, %env-vars) {
  my @xs = %env-vars.keys.map({ "export {$_}={%env-vars{$_}}" });
  spurt $outp, @xs.push($shell-cmd).join("\n");
  say "wrote $outp";
}

sub read-config($config-path) {
  use Config::Simple;
  my $conf = Config::Simple.read($config-path) :f('ini');
  return $conf<config>;
}

sub parse-bam-map($path) returns Hash {
  my %d = $path.IO.lines.flatmap(*.split("\t"));
  return %d;
}

sub extract-chr(Str $filename) {
  ~$0 if $filename ~~ /chr(\d+)/ or die("Unable to extract chrom name from $filename");
}


sub parse-vcf-map($vcf-dir) returns Hash {
  my Str @vcf-paths= $vcf-dir.IO.dir(test => / '.' vcf $/)>>.Str;
  my Str @vcf-names = @vcf-paths.map(*.IO.basename);
  my @chr-ids = @vcf-paths.map(&extract-chr);
  my %d;
  %d{@chr-ids} = @vcf-paths;
  return %d;
}

sub is-failed-job($log) {
  slurp($log) ~~ / CANCELLED /;
}

#| a job has failed if error log contains the word CANCELLED
sub find-failed-jobs($job-dir) {
  $job-dir.IO.dir(test => / '.' err $/).grep(&is-failed-job);
}
