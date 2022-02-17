#!/usr/bin/env perl

use strict;
use Getopt::Long;

my $usage = qq{
perl my_script.pl
  Getting help:
    [--help]

  Input:
    [--genome_fai filename]
		The name of the assembly fasta index
    [--bed filename]
		A bed file of target regions
    [--hints filename]
		A hints file in GFF format
    [--aug_conf filename]
		An augustus custom config file with hint weights
  Ouput:    
    [--outfile filename]
        The name of the output file. By default the output is the
        standard output
};

# augustus_from_regions.pl --genome_fai $genome_fai --bed $regions --hints $hints --aug_conf $AUG_CONF --isof $params.isof --utr $params.UTR
my $outfile = undef;
my $infile = undef;
my $genome_fai = undef;
my $chunk_length = 3000000;
my $hints = undef;
my $aug_conf = undef;
my $options = "";
my $utr = undef;
my %dictionary;
my $model = undef;
my $help;

GetOptions(
    "help" => \$help,
    "infile=s" => \$infile,
    "model=s" => \$model,
    "genome_fai=s" => \$genome_fai,
    "hints=s" => \$hints,
    "utr=s" => \$utr,
    "options=s" => \$options,
    "chunk_length=s" => \$chunk_length,
    "aug_conf=s" => \$aug_conf,
    "outfile=s" => \$outfile);

# Print Help and exit
if ($help) {
    print $usage;
    exit(0);
}

if ($outfile) {
    open(STDOUT, ">$outfile") or die("Cannot open $outfile");
}

my $overlap = ($chunk_length/6) ;

my @chromosomes;

# Read FAI file to get list of scaffolds

open (my $FAI, '<', $genome_fai) or die "FATAL: Can't open file: $genome_fai for reading.\n$!\n";

while (<$FAI>) {

	my $line = $_;
	chomp($line);

	my ($chr,$len,$a,$b,$c) = split("\t",$line);
	push(@chromosomes,$chr);
	$dictionary{$chr} = $len;
	
}

close($FAI);

# Go over the regions from the bed file and define jobs

my $counter = 0;

foreach my  $key  (@chromosomes) { 

	my $len = $dictionary{$key};

	if ($len <= $chunk_length) {

		$counter += 1;
	
		my $output = $counter . "_" . "augustus_chunk.out" ;

		my $command = "augustus --exonnames=on --species=$model --softmasking=1 $options --UTR=$utr --extrinsicCfgFile=$aug_conf --hintsfile=$hints --predictionStart=1 --predictionEnd=$len  $key.fa > $output" ;
		printf $command . "\n" ;

	} else {

		my $start = 1;
		my $end = undef;
		my $previous_end = undef;

		while ($start < $len) {
	
			$counter += 1;

			$end = $start + $chunk_length;

			last if ($previous_end >= $len);

			if ($end > $len) {
				$end = $len;
			}

			#my $output = "augustus_chunk_" . $counter . ".out" ;
			my $output = $counter . "_" . "augustus_chunk.out" ;

			my $command = "augustus --species=$model --softmasking=1 $options --UTR=$utr --extrinsicCfgFile=$aug_conf --hintsfile=$hints --predictionStart=$start --predictionEnd=$end $key.fa > $output" ;
                	printf $command . "\n" ;	
		
			$start += ($chunk_length-$overlap);
			$previous_end = $end;
		}
		
	}
}

