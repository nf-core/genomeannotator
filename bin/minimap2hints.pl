#!/usr/bin/env perl
# GFF from Minimap to hints format for augustus

use strict;
use Getopt::Long;


my $usage = qq{
perl my_script.pl
  Getting help:
    [--help]

  Input:
    [--infile filename]
		The name of the file to read. 
    [--source string]
		A valid source for processing (est, protein or trinity)
    [--pri integer]
		Priority of the resulting hints (default: 3)

  Ouput:    
    [--outfile filename]
        The name of the output file. By default the output is the
        standard output
};

my $outfile = undef;
my $infile = undef;
my $source = "est2genome";
my $GeneID = undef;
my $pri = 3;
my $help;

my $src = "E";
my $pri = 3;
my $hintfeature = "exonpart";

my $help;

GetOptions(
    "help" => \$help,
    "source=s" => \$source,
    "src=s" => \$src,
    "pri=i" => \$pri,
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

# open the minimap GFF file
open (my $IN, '<', $infile) or die "FATAL: Can't open file: $infile for reading.\n$!\n";

my @bucket;
my $previous_group = "placeholder";
my $previous_end = 1;

while (<$IN>) {
	
	my $line = $_;
	chomp $line;

	if ( $line =~ /^#.*/ ) {
		printf $line . "\n";
	} else {

		my ($chr,$origin,$feature,$from,$to,$score,$strand,$phase,$info) = split("\t",$line);
		my $group = (split /[;,=]/ , $info)[1];

		# make an intron if this is still the same aligned sequence
		if ($previous_group eq $group) {
			my $intron_start = $previous_end+1;
			my $intron_end = $from-1;
			my $intron = $chr . "\t" . $source . "\tintron\t" . $intron_start . "\t" . $intron_end . "\t" . $score . "\t" . $strand . "\t" . $phase . "\t" . "src=$src;grp=$group;pri=$pri" ;
			push(@bucket,$intron);
		}

		my $entry =  $chr . "\t" . $source . "\t" . $hintfeature . "\t" . $from . "\t" . $to . "\t" . $score . "\t" . $strand . "\t" . $phase . "\t" . "src=$src;grp=$group;pri=$pri" ;
		
		# Collect mappings until a new group starts
		if ($previous_group ne $group) {
			# only consider multi-hit, i.e. spliced, mappings
			# a lot of single-exon mappings are noise from sequencing and or mapping
			if (scalar(@bucket) > 1) {
				foreach my $e (@bucket){
					printf $e . "\n" ;
				}
			} else {
				print STDERR "Skipping single exon group $group\n";
			}
			@bucket = ();
			
		} 

		$previous_group = $group;
		$previous_end = $to;
		push(@bucket,$entry);
	}

}

if (scalar(@bucket) > 1) {
	foreach my $e (@bucket){
        	printf $e . "\n" ;
        }
}

close $IN;
