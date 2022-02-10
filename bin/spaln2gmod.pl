#!/usr/bin/env perl

use strict;
use Getopt::Long;
use Data::Dumper;

my $usage = qq{
perl my_script.pl
  Getting help:
    [--help]

  Input:
    [--infile filename]
		The name of the file to read. 
  Ouput:    
    [--outfile filename]
        The name of the output file. By default the output is the
        standard output
};

my $outfile = undef;
my $infile = undef;
my $help;

GetOptions(
    "help" => \$help,
    "infile=s" => \$infile,
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

my $this_est = undef;
my @bucket;
my $counter = 0;
my $mrna_counter = 0;
my $parent_id = undef;

while (<$IN>) {

        my $line = $_;
        chomp $line;

	next if ($line =~ /^#.*/) ;
	
        my ($seq,$source,$feature,$start,$stop,$phase,$strand,$score,$info) = split("\t",$line);

	my %attributes ;
	
	foreach my $i (split ";" , $info) {
		my ($key,$value) = (split "=" , $i);
		$attributes{$key} = $value ;
	}

        my %entry = ( "seq" => $seq, "source" => $source, "feature" => $feature, "start" => $start, "stop" => $stop, "phase" => $phase, "strand" => $strand, "score" => $score, "attributes" => \%attributes );

	if ($feature eq "mRNA") {
		$mrna_counter += 1 ;
		$counter = 1;
		$parent_id = "ProteinAlign-" . $mrna_counter ;
		printf $seq . "\t" . "protein2genome" . "\t" . "protein_match" . "\t" . $start .  "\t" . $stop . "\t" . $score . "\t" . $strand . "\t" . "." . "\tID=ProteinAlign-" . $mrna_counter . ";Target=" . $attributes{"ID"} . "\n" ;
	} elsif ($feature eq "cds" || $feature eq "CDS") {
		printf $seq . "\t" . "protein2genome" . "\t" . "match_part" . "\t" . $start .  "\t" . $stop . "\t" . $score . "\t" . $strand . "\t" . "." . "\tID=ProteinAlign-" . $mrna_counter . "." . $counter . ";Parent=" . $parent_id . ";Target=" . $attributes{"Parent"} . "\n";
                $counter += 1 ;
	}	

}

