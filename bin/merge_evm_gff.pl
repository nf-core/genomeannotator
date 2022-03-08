#!/usr/bin/env perl
# Merge outputs from EVM 

use strict;
use Getopt::Long;

my $usage = qq{
perl my_script.pl
  Getting help:
    [--help]

  Input:
    [--partitions filename]
		The name of the file to read. 
  Ouput:    
    [--gff filename]
        The name of the output file. By default the output is the
        standard output
};

my $gff = undef;
my $partitions = undef;
my $help;

GetOptions(
    "help" => \$help,
    "partitions=s" => \$partitions,
    "gff=s" => \$gff);

# Print Help and exit
if ($help) {
    print $usage;
    exit(0);
}

if ($gff) {
    open(STDOUT, ">$gff") or die("Cannot open $gff");
}

open (my $IN, '<', $partitions) or die "FATAL: Can't open file: $partitions for reading.\n$!\n";

my $previous_folder = undef;

while (<$IN>) {
	chomp;
	my $line = $_;

	my @elements = split("\t", $line);

	my $folder = @elements[1];
	
	unless ($previous_folder && $previous_folder eq $folder) {

		$previous_folder = $folder;
		my $gff_file = "${folder}/evm.out.gff3" ;

		if (-e $gff_file) {
			system("cat $gff_file >> $gff");
		} else {
			warn "Could not find expected GFF file $gff_file\n" ;
		}
	}

}
