#!/usr/bin/env perl

# Convert a lift-over GTF file from Kraken to a valid GFF3 format
# This includes dealing with models split across contigs

use strict;
use Getopt::Long;
use Scalar::Util qw(openhandle);
use FindBin;
use lib "$FindBin::Bin/perl_lib/";
use Converter ;


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

# Any output will the GFF3:
my $gffout = Bio::Tools::GFF->new(-gff_version => 3);

my $conversion = Converter::EnsEMBL2GFF3->new($infile);

print "##gff-version 3\n" ;


foreach my $feature (@$conversion) {
	print $feature->gff_string($gffout) , "\n";
}

# --------------

sub msg {
  my $t = localtime;
  my $line = "[".$t->hms."] @_\n";
}

sub runcmd {
  msg("Running:", @_);
  system(@_)==0 or err("Could not run command:", @_);
}

sub err {
  msg(@_);
  exit(2);
}


