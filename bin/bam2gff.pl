#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;

# This is a rip-off from Brian Haas's Sam_to_gtf.pl converter bundled with PASA
# Needed this as a standalone version.

my %PATH_COUNTER;

my $bam = $ARGV[0] ;

open BAM,"samtools view $bam |";

        while(<BAM>){
        next if(/^(\@)/);  ## skipping the header lines (if you used -h in the samools command)
        s/\n//;  s/\r//;  ## removing new line
        my @sam = split(/\t+/);  ## splitting SAM line into array

	my %entry = ( "qname" => $sam[0], "flag" => $sam[1], "rname" => $sam[2], "pos" => $sam[3], "mapq" => $sam[4], 
		"cigar" => $sam[5], "rnext" => $sam[6], "pnext" => $sam[7], "tlen" => $sam[8], "seq" => $sam[9], "qual" => $sam[10] );


	# Skip this entry if it has no sequence
	if ($entry{'seq'} eq '*') {
		next ; 
	}

	# query is unmapped
	if ($entry{'flag'} & 0x0004) {
		next;
	}

	my $num_mismatches = 0;

	if ( join("\t",@sam) =~ /NM:i:(\d+)/) {
		$num_mismatches = $1;
        }

	# get the strand of the alignment
	my $strand = undef;
	if ($entry{"flag"} == 0) {
		$strand = "+" ;
	} elsif ($entry{"flag"} == 16) {
		$strand = "-" ;
	# Flag suggests other factors, will ignore this mapping
	} else {
		next;
	}	
	
	$entry{"strand"} = $strand ;
	
	my $read_name = $entry{"qname"} ;
	my $scaff_name = $entry{"rname"};
	
	my ($genome_coords_aref, $query_coords_aref) = get_aligned_coords(%entry);

	my $align_len = 0;

	foreach my $coordset (@$genome_coords_aref) {
                $align_len += abs($coordset->[1] - $coordset->[0]) + 1;
        }
	# Check this...
	next if ($align_len eq 0);

	my $per_id = sprintf("%.1f", 100 - $num_mismatches/$align_len * 100); 

	# discard all mappings below 80%
	if ($per_id < 90.0) {
		next;
	}

	my $align_counter = "$read_name.p" . ++$PATH_COUNTER{$read_name};

	my @genome_n_trans_coords;
        
        while (@$genome_coords_aref) {
            my $genome_coordset_aref = shift @$genome_coords_aref;
            my $trans_coordset_aref = shift @$query_coords_aref;

            my ($genome_lend, $genome_rend) = @$genome_coordset_aref;
	    
            my ($trans_lend, $trans_rend) = sort {$a<=>$b} @$trans_coordset_aref;

            push (@genome_n_trans_coords, [ $genome_lend, $genome_rend, $trans_lend, $trans_rend ] );

        }

	my @merged_coords;
        push (@merged_coords, shift @genome_n_trans_coords);

        my $MERGE_DIST = 10;
        while (@genome_n_trans_coords) {
            my $coordset_ref = shift @genome_n_trans_coords;
            my $last_coordset_ref = $merged_coords[$#merged_coords];
            
            if ($coordset_ref->[0] - $last_coordset_ref->[1] <= $MERGE_DIST) {
                # merge it.
                $last_coordset_ref->[1] = $coordset_ref->[1];

                if ($strand eq "+") {
                    $last_coordset_ref->[3] = $coordset_ref->[3];
                } else {
                    $last_coordset_ref->[2] = $coordset_ref->[2];
                }
            }
            else {
                # not merging.
                push (@merged_coords, $coordset_ref);
            }
        }

	foreach my $coordset_ref (@merged_coords) {
            my ($genome_lend, $genome_rend, $trans_lend, $trans_rend) = @$coordset_ref;
            print join("\t",
                       $scaff_name,
                       "est2genome",
                       "cDNA_match",
                       $genome_lend, $genome_rend,
                       $per_id,
                       $strand,
                       ".",
                       "ID=$align_counter;Target=$read_name $trans_lend $trans_rend") . "\n";
        }
        #print "\n";
        
        
}

sub get_aligned_coords {

	my %entry = @_;

	my $genome_lend = $entry{"pos"};

	my $alignment = $entry{"cigar"};
	my $query_lend = 0;

	my @genome_coords;
	my @query_coords;

	$genome_lend--;

	while ($alignment =~ /(\d+)([A-Z])/g) {

		my $len = $1;
		my $code = $2;
		
		unless ($code =~ /^[MSDNIH]$/) {
			die  "Error, cannot parse cigar code [$code] ";
		}
		
		#print "parsed $len,$code\n";
		
		if ($code eq 'M') { # aligned bases match or mismatch
			
			my $genome_rend = $genome_lend + $len;
			my $query_rend = $query_lend + $len;
			
			push (@genome_coords, [$genome_lend+1, $genome_rend]);
			push (@query_coords, [$query_lend+1, $query_rend]);
			
			# reset coord pointers
			$genome_lend = $genome_rend;
			$query_lend = $query_rend;
		}
		elsif ($code eq 'D' || $code eq 'N') { # insertion in the genome or gap in query (intron, perhaps)
			$genome_lend += $len;
			
		}

		elsif ($code eq 'I'  # gap in genome or insertion in query 
               ||
               $code eq 'S' || $code eq 'H')  # masked region of query
        { 
            $query_lend += $len;

		}
	}

	 ## see if reverse strand alignment - if so, must revcomp the read matching coordinates.
    	if ($entry{"strand"} eq '-') {

        my $read_len = length($entry{"seq"});
        unless ($read_len) {
            die "Error, no read length obtained from entry";
        }

        my @revcomp_coords;
        foreach my $coordset (@query_coords) {
            my ($lend, $rend) = @$coordset;

            my $new_lend = $read_len - $lend + 1;
            my $new_rend = $read_len - $rend + 1;

            push (@revcomp_coords, [$new_lend, $new_rend]);
        }

        @query_coords = @revcomp_coords;

    }

	return(\@genome_coords, \@query_coords);
}
;
