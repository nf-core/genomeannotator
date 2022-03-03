#!/usr/bin/env perl
# Script to generate new, standardized IDs for features in a GFF file

use strict;
use Getopt::Long;

my $usage = qq{
perl my_script.pl
  Getting help:
    [--help]

  Input:
    [--gff filename]
		The name of the file to read. 
  Ouput:    
    [--outfile filename]
        The name of the output file. By default the output is the
        standard output
};

my $outfile = undef;
my $gff = undef;
my $help;

GetOptions(
    "help" => \$help,
    "gff=s" => \$gff,
    "outfile=s" => \$outfile);

# Print Help and exit
if ($help) {
    print $usage;
    exit(0);
}

if ($outfile) {
    open(STDOUT, ">$outfile") or die("Cannot open $outfile");
}

open (my $GFF, '<', $gff) or die "FATAL: Can't open file: $gff for reading.\n$!\n";

my $this_gene_id = 1000;
my $this_mrna_id = 1000;

# PARSE GFF FILE
while (<$GFF>) {
	chomp; 
	my $line = $_; 
	
	if ($line =~ /^#.*/) {

		printf $line . "\n";
	} else {

		my %entry = parse_gff($line);
	
		if ( $entry{"feature"} eq "gene" ) {
			$this_gene_id += 1;
			$entry{"attributes"}{"ID"} = "gene.$this_gene_id" ;
		} elsif ($entry{"feature"} eq "mRNA" || $entry{"feature"} eq "transcript") {
			$this_mrna_id += 1;
			$entry{"attributes"}{"ID"} = "mRNA.$this_mrna_id" ;
			$entry{"attributes"}{"Parent"} = "gene.$this_gene_id" ;
		} elsif ( $entry{"feature"} eq "CDS" ) {
			$entry{"attributes"}{"ID"} = "mRNA.$this_mrna_id.cds" ;
			$entry{"attributes"}{"Parent"} = "mRNA.$this_mrna_id" ;		
		} else {
			$entry{"attributes"}{"Parent"} = "mRNA.$this_mrna_id" ;
		}
		
		gff_print(%entry) ;
	}
	
}

close $GFF;

# -----------
# - METHODS - 

sub gff_print() {
	
	chomp;
	my %data = @_;
	
	my $attribs = "";
	foreach my $key (keys %{$data{"attributes"}} ) {
		my $value = $data{"attributes"}{$key};
		$attribs .= $key . "=" . $value . ";" ;
	}
	printf $data{"seq_name"} . "\t" . $data{"source"} . "\t" . $data{"feature"} . "\t" . $data{"seq_start"} . "\t" . $data{"seq_end"} . "\t" . $data{"score"} . "\t" . $data{"strand"} . "\t" . $data{"phase"} . "\t" . $attribs ."\n" ;
		
}

sub parse_gff() {
	
	chomp;
	my %data = $_;
	
	my $line = $_;
	my %answer;
	my %attributes;
	
	my @temp = split("\t", $line);
	
	$answer{"seq_name"} = @temp[0];
	$answer{"source"} = @temp[1];
	$answer{"feature"} = @temp[2];
	$answer{"seq_start"} = @temp[3];
	$answer{"seq_end"} = @temp[4];
	$answer{"score"} = @temp[5];
	$answer{"strand"} = @temp[6];
	$answer{"phase"} = @temp[7];
	
	my @attribs = split(";", @temp[8]);
	foreach my $attrib (@attribs) {
		$attrib =~ s/^\s+//;
		my ($key,$value) = split("=", $attrib);
		$attributes{$key} = $value;
	}
	
	$answer{"attributes"} = \%attributes;
	
	return %answer ;
}



