#!/usr/bin/env perl

use strict;
use Getopt::Long;

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
my $ref_fa = undef;
my $query_fa = undef;
my $chain = undef;
my $help;

GetOptions(
    "help" => \$help,
    "ref_fa=s" => \$ref_fa,
    "query_fa=s" => \$query_fa,
    "chain=s" => \$chain,
    "outfile=s" => \$outfile);

# Print Help and exit
if ($help) {
    print $usage;
    exit(0);
}

if ($outfile) {
    open(STDOUT, ">$outfile") or die("Cannot open $outfile");
}


printf "[genomes]\n";

printf "REF\t$ref_fa\n";
printf "QUERY\t$query_fa\n";
printf "\n";
printf "[pairwise-maps]\n";
printf "REF\tQUERY\t$chain\n";

