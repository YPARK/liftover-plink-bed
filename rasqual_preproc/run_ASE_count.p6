use Config::Simple;

my $conf = Config::Simple.read('config.ini') :f('ini');
$conf = $conf<config>;

my %gatk_env = (
  genome_ref => $conf<genome-ref>,
  output_csv => 'TCC678_chr1.csv',
  input_bam => "$conf<rna-dir>/input/batch4_TCC678_3_22_t0_150622_SN163_0652_AC7EUNACXX_L1_ACAGTG.bam",
  input_vcf => "$conf<vcf-dir>/chr1.phased.vcf");


%*ENV.append(%gatk_env);
shell "bash countASE.job"
