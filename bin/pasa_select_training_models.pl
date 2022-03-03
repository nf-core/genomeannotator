#!/usr/bin/env perl

use strict;
use Getopt::Long;
use URI::Encode qw(uri_encode uri_decode);
use Data::Dumper;

my $usage = qq{
perl my_script.pl
  Getting help:
    [--help]

  Input:
    [--infile filename]
		The name of the file to read. 
    [--nmodels int]
		How many models to select for training (default: 1000)
  Ouput:    
    [--outfile filename]
        The name of the output file. By default the output is the
        standard output
};

my $outfile = undef;
my $infile = undef;
my $nmodels = 1000;
my $help;

GetOptions(
    "help" => \$help,
    "infile=s" => \$infile,
    "nmodels=i" => \$nmodels,
    "outfile=s" => \$outfile);

# Print Help and exit
if ($help) {
    print $usage;
    exit(0);
}

if ($outfile) {
    open(STDOUT, ">$outfile") or die("Cannot open $outfile");
}

open (my $IN, '<', $infile) or die "FATAL: Can't open file: $infile for reading.\n$!\n";

my $valid = 0;

my %score_table;
my @scores;

my $gene_id;

while (<$IN>) {

	chomp;
	my $line = $_;

	if ($line =~ /^#.*/) {
		next;
	}
	my @elements = split "\t", $line;

	my %entry = ( "seq_name" => $elements[0], "source" => $elements[1], "feature" => $elements[2], "start" => $elements[3], "stop" => $elements[4],
		"score" => $elements[5], "strand" => $elements[6], "phase" => $elements[7], "attributes" => $elements[8]);

	my $attributes = $entry{'attributes'};
	
	my %attribs ;
	foreach my $pair ( split(";",$attributes) ) {
		my ($key,$value) = split("=",$pair);
		$attribs{$key} = $value;
	}

	if ( $entry{'feature'} eq "gene" ) {

		if ($entry{'attributes'} =~ /.*complete.*/ ) {

			$valid = 1;

			my $decoded = uri_decode($attributes);
			my $score = (split "=",$decoded)[-1];

			push(@scores,$score);

			$gene_id = $attribs{"ID"};
			$score_table{$gene_id} =  { "score" => $score , "elements" => [] };
		} else {
			$valid = 0;
		}
	}

	if ($valid == 1) {
		die "Uhm no id here?!\n" unless (defined $gene_id);
		push @{ $score_table{ $gene_id }{"elements"} },$line ;
	}
}

close($IN);

# Determine minimum score to include a gene

my $min_score = undef;

my @sorted_scores = sort { $b <=> $a } @scores;

if ( (scalar @sorted_scores) < $nmodels) {
	$min_score = @sorted_scores[-1];
} else {
	$min_score = (@sorted_scores[0..$nmodels-1])[-1] ;
}

# GFF header
printf "###gff-version 3\n" ;

foreach my $gene_id (keys %score_table) {
	
	my %data = %{ $score_table{$gene_id} };

	my $score = $data{"score"} ;

	next if ($score < $min_score);

	my $lines = $score_table{$gene_id}{"elements"} ; 

	foreach my $line (@$lines) {
		
		printf uri_decode($line) . "\n";
	}
}
