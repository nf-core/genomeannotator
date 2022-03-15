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

	# a match group is ending, produce output
	if (defined $this_est && $this_est ne $attributes{"ID"} ) {
		process_bucket(\@bucket);
		@bucket = ();
	}
	
	push  @bucket, \%entry;

	$this_est = $attributes{"ID"};
}

sub process_bucket {

        my @hits = @{$_[0]};

	# Get boundary information for this match group
	my $first_hit = @hits[0];
	my $last_hit = @hits[-1];
	my $est_id = $first_hit->{"attributes"}->{"ID"};

	my $start = $first_hit->{"start"};
	my $stop = $last_hit->{"stop"};

	my $strand = $first_hit->{"strand"} ;

	# Iterate over all hits, sorted depending on the inferred strand
	my $counter = 0;

	my @sorted_hits;

	if ($strand eq "-") {
		@sorted_hits = sort { $b->{"start"} <=> $a->{"start"} } @hits;
	} else {
		@sorted_hits = sort { $a->{"start"} <=> $b->{"start"} } @hits;

	}

	# The container for this match group
	printf $first_hit->{"seq"} . "\t" . $first_hit->{"source"} . "\t" . "expressed_sequence_match" . "\t" . $start . "\t" . $stop . "\t" . $first_hit->{"score"} . "\t" . $strand . "\t" . "." . "\tID=" . $est_id . ";Name=" . $est_id . "\n";

	# each member of the match group
        foreach my $hit (@sorted_hits) {
                $counter += 1;
        	my $match_id = $est_id . "." . $counter ;

        	printf $hit->{"seq"} . "\t" . $hit->{"source"} . "\t" . "match_part" . "\t" . $hit->{"start"} . "\t" . $hit->{"stop"} . "\t" . $hit->{"score"} . "\t" . $hit->{"strand"} . "\t.\t" . "ID=" . $match_id . ";Parent=" . $est_id . "\n";
        }

}
	
