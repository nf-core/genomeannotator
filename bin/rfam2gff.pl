#!/usr/bin/env perl

use strict;
use Getopt::Long;

# Convert a CMSearch TBL out file into a GFF file using RFam SQL table as biotype lookup

my $usage = qq{
perl my_script.pl
  Getting help:
    [--help]

  Input:
    [--infile filename]
		The name of the file to read. 
    [--family filename]
		Name of the Rfam family.txt SQL dump

  Ouput:    
    [--outfile filename]
        The name of the output file. By default the output is the
        standard output
};

my $outfile = undef;
my $infile = undef;
my $family = undef;
my $help;

GetOptions(
    "help" => \$help,
    "infile=s" => \$infile,
    "family=s" => \$family,
    "outfile=s" => \$outfile);

# Print Help and exit
if ($help) {
    print $usage;
    exit(0);
}

if ($outfile) {
    open(STDOUT, ">$outfile") or die("Cannot open $outfile");
}


my %families;
open (my $FAM, '<', $family) or die "FATAL: Can't open file: $family for reading.\n$!\n";

foreach my $line (<$FAM>) {

        chomp($line);

	my @elements = split "\t" , $line;

	my $rfam_acc = @elements[0];

	my $biotype = @elements[18];
	my $this_type = "skip";
	if ( $biotype =~ /^Gene.*/) {
		$this_type = (split ";", $biotype)[1];
		$this_type =~  s/^\s+|\s+$//g ;
	}

	$families{$rfam_acc} = $this_type;
}

close($FAM);

open (my $IN, '<', $infile) or die "FATAL: Can't open file: $infile for reading.\n$!\n";

chomp(my @lines = <$IN>);

my @columns = ( "target name", "accession_target", "query_name", "accession mdl", "mdl" , "mdl from", "mdl to", "seq from", "seq to", "strand", "trunc", "pass", "gc", "bias", "score", "E-value", "inc", "description of target" );

my $counter = 1000;

foreach my $line (@lines) {

	next if ($line =~  /^#.*/) ;

	my @elements = split /\s+/, $line ;
	my %data;

	my $idx = 0;
	foreach my $e (@elements) {
		my $column = @columns[$idx];
		$data{$column} = $e;
		$idx += 1;
	}


	next if ($data{"trunc"} eq "yes");

	my $biotype = $families{$data{"accession mdl"}};

	next if ($biotype eq "skip");

	# Make a GFF compliant entry

	# seq source type from to score  strand phase  info

	my $id = $data{"accession mdl"} . "_"  . $counter ;

	printf $data{"target name"} . "\tRFam\t" . "ncRNA_gene" . "\t" . $data{"seq from"} . "\t" . $data{"seq to"} . "\t" . $data{"score"} . "\t" . $data{"strand"} . "\t.\t" . "ID=" . $id  . ";Name=" . $data{"query_name"} . "\n";
        printf $data{"target name"} . "\tRFam\t" . $biotype. "\t" . $data{"seq from"} . "\t" . $data{"seq to"} . "\t" . $data{"score"} . "\t" . $data{"strand"} . "\t.\t" . "ID=" . $id  . "-T;Parent=" . $id . ";Name=" . $data{"query_name"} . "\n";
        printf $data{"target name"} . "\tRFam\t" . "exon" . "\t" . $data{"seq from"} . "\t" . $data{"seq to"} . "\t" . $data{"score"} . "\t" . $data{"strand"} . "\t.\t" . "ID=" . $id  . "-E;Parent=" . $id . "-T;Name=" . $data{"query_name"} . "\n";

	$counter += 1;

}

close($IN);
