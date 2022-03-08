#!/usr/bin/env perl

use strict;
use Getopt::Long;

my $usage = qq{
perl my_script.pl
  Getting help:
    [--help]

  Input:
    [--gtf filename]
		The name of the file to read. 
    [--source name]

    [--pri value]

  Ouput:    
    [--outfile filename]
        The name of the output file. By default the output is the
        standard output
};

my $outfile = undef;
my $gtf = undef;
my $source = "T";
my $pri = "4";
my $help;

GetOptions(
    "help" => \$help,
    "gtf=s" => \$gtf,
    "source=s" => \$source,
    "pri=i" => \$pri,
    "outfile=s" => \$outfile);

# Print Help and exit
if ($help) {
    print $usage;
    exit(0);
}

if ($outfile) {
    open(STDOUT, ">$outfile") or die("Cannot open $outfile");
}

open (my $IN, '<', $gtf) or die "FATAL: Can't open file: $gtf for reading.\n$!\n";

my $is_first_cds;
my $is_last_cds;

while (<$IN>) {

        my $line = $_;
        chomp $line;

	# ctg.000005F     EVM2.2  exon    273274  273476  .       -       .       gene_id "ML000115a"; transcript_id "ML000115a-1"; gene_name "ML000115a;";

        my ($seq,$src,$feature,$start,$stop,$score,$strand,$phase,$info) = split(/\t/,$line);

	my $hint_type = "" ;
	my $margin = 0;

	if ($feature eq "transcript") {
		$is_first_cds = 0;
		$is_last_cds = 0;
	} elsif ($feature eq "CDS") {
		$hint_type = "CDSpart";
		if ($stop-$start > 5) {
			$margin = 5;
		}
	} elsif ($feature eq "exon") {
		$hint_type = "exonpart";
	} elsif ($feature =~ /.*UTR.*/) {
		$hint_type = "UTRpart";
	} else {
		next;
	}
	
	my %attribs;

        my @fields = split(";",$info);

        foreach my $f (@fields) {
                my ($key,$value) = split(" ",$f);
                $attribs{$key} = $value;
        }

	my $group = $attribs{"transcript_id"};

	$group =~ s/\"//g ;
	
	printf $seq . "\t" . "transmapped" . "\t" . $hint_type . "\t" . ($start+$margin) . "\t" . ($stop-$margin) . "\t" . "." . "\t" . $strand . "\t" . "." . "\t" . "group=$group;src=$source;pri=$pri\n";

}

close($IN);

