#!/usr/bin/perl -w

package Converter::EnsEMBL2GFF3 ;

use base 'Converter';
use Data::Dumper;
=head1 SYNOPSIS



=head1 DESCRIPTION

	A library to convert EnsEMBL GTF to valid GFF3.
	Inherits from BILS::Converter
	
=cut	


sub new {
	
	my ($self, $file) = @_  ;
	
	#my $gtfio = Bio::Tools::GFF->new(-file => $file, -gff_version => 2.5);
        my $gtfio = Bio::Tools::GFF->new(-file => $file, -gff_version => 2);	
	my @answer = ();   # Will hold the modified features
	my @bucket = ();
	my $skip_lncrna = 0;

	while( my $feature = $gtfio->next_feature()) {

		if ($feature->primary_tag eq "gene") {
			if ($feature->gff_string =~ /.gene_biotype \"lncRNA.*/) {
				$skip_lncrna = 0;
				printf STDERR "Skipping lncRNA!\n";
			} else {
				$skip_ncrna = 1;
			}
		} 
	
		my @gvalues = $feature->get_tag_values('gene_id');
		my $gene_id = shift @gvalues ;

		# We stream, so for each transcript we check whether this is a new gene 
		# and whether we have things sitting in memory for processing	
		if ( defined $this_gene_id and $this_gene_id ne $gene_id) {
			#printf STDERR "New gene encountered...\n";
			if ($skip_lncrna == 0) {
				my $new_features = reconstruct_locus_without_transcripts_with_seq_id(@bucket);
				push(@answer,@$new_features);
			}
	
			@bucket = (); # Empty bucket for new gene

		}

		$this_gene_id = $gene_id;

		# We build transcripts directly from the exons, so can skip this feature (if present)
		# This is because some GTF files don't have transcript-level features, so can't rely on them (EnsEMBL)

		next if ( $feature->primary_tag eq 'transcript' or $feature->primary_tag eq 'gene');

		push(@bucket,$feature);	

	}

	# empty the bucket one last time:
	my $new_features = reconstruct_locus_without_transcripts_with_seq_id(@bucket);
	push(@answer, @$new_features);
	
	
	return \@answer;
}



#########################################
#### DEALING WITH FEATURES ACROSS CONTIGS
#########################################

sub reconstruct_locus_without_transcripts_with_seq_id {
	
	# All features belonging to the same gene
	my $features = \@_;
	
	# Take all features and bin them by transcript_id	

	my %bin = _group_features_by_transcript_and_seq_id(@$features);
	
	# Build transcript from all features in the group
		
	my @answer = ();

	# Some annotations (like lift-overs) can be split across scaffolds/contigs
	my $is_split = 0;
	my $appendix = ""; # A variable to store appendices for split genes
	# Check wether this gene is split across scaffolds
	if ( (keys %bin) > 1) {
		$is_split = 1;
	}		

	my $seq_counter = 0;

	while (my ($seq_id,$transcript_hash) = each %bin) {

		$seq_counter += 1;
		$appendix = "partial_part-$seq_counter" ;

		# !!! These are all transcripts on the same sequence !!!

		# Collect transcripts for gene reconstruction
		my @transcripts = ();
		my $exon_counter = 0;
		
		while (my ($transcript_id,$features) = each %$transcript_hash) {
			
			my $t_feature = _build_transcript_from_exons_with_seq_id(@$features);

			if ($is_split == 1) {
				$t_feature = _update_feature_id($t_feature,$appendix) ;
			}

			push(@transcripts,$t_feature);

			unshift (@{ $bin{$seq_id}{$transcript_id} }, $t_feature ) ;	
		}

		# Build the gene container

		my $gene_feature = _build_gene_from_transcripts_with_seq_id(@transcripts);

		# Gene into array
		push(@answer,$gene_feature);

		# All other features to array, neatly ordered and modified where needed
		while ( my ($transcript_id, $values) = each(%$transcript_hash) ) {

			# Features other than mRNAs and genes need to have new stable IDs, let's build some...
			my $feature_counter = 0;

			foreach my $f (@$values) {

			# We have cleaned up transcripts and genes, need to sort out all other features now:

				unless ($f->has_tag('ID')) {
					$feature_counter += 1;

					my $id = $transcript_id . "-" . $f->primary_tag . "-" . $feature_counter ; # A crummy new stable ID...could be done better.

					my $newf = Bio::SeqFeature::Generic->new(-start => $f->start, -primary_tag => $f->primary_tag , -end => $f->end, -frame => $f->frame, -strand => $f->strand , -seq_id => $f->seq_id, -source_tag => $f->source_tag, -tag => { 'ID' => $id  , 'Parent' => $transcript_id}) ;
					
					$newf = append_attributes($newf,$f);

					if ($is_split == 1) {
						$newf = _update_feature_id($newf,$appendix);
					}
					push(@answer,$newf);
				}
				else{
					push(@answer,$f);
				}

				
			}
		}
			
	} # End sequence region

	return \@answer;
}

sub append_attributes{
	my $newfeature = shift;
	my $feature = shift;
	@tags = $feature->get_all_tags();
	foreach my $tag (@tags) {
		my @temp = $feature->get_tag_values($tag);
        $newfeature->add_tag_value($tag,$temp[0]);
	}
	return $newfeature;
}

sub _update_feature_id {

	my $feature = shift ;
	my $appendix = shift;

	my @tags = ( 'ID' , 'Parent' ) ;

	foreach my $tag (@tags) {
	
		if ($feature->has_tag($tag) ) {
			my @temp = $feature->get_tag_values($tag);
			my $current_id = shift @temp;
	        	my $new_id = $current_id . "_" . $appendix ;
			$feature->remove_tag($tag);
        		$feature->add_tag_value($tag,$new_id);
		}
	}

	return $feature;
}

# Deals with features across contigs
sub _group_features_by_transcript_and_seq_id {
	
	my @features = @_;
	
	my %bin ;
	
	foreach my $feature (@features) {

		if ($feature->start < 1) {
			$feature->start(1);
		}
				
		my $source_tag = $feature->source_tag;
		my $primary_tag = $feature->primary_tag;
		
		# If a gene is split across multiple sequences,
		# we need to build separate genes for each sequence - 
		# this keeps track of that.
		
		my $seq_id = $feature->seq_id;
				
		# We need to reorganize feature relationships into parent/child:
		my $this_id = undef; 
		my $parent_id = undef;
		
		# We always need to know about the transcript_id, record it...
		my @tvalues = $feature->get_tag_values('transcript_id');
		my $transcript_id = shift @tvalues ;
		
		# Group features by transcripts/mRNA and seq_id
			
		if ( !exists( $bin{$seq_id} ) ) {
			$bin{$seq_id} = {};
		}

		if ( !exists( $bin{$seq_id}{$transcript_id} ) ) {
			$bin{$seq_id}{$transcript_id} = [];		
		}

		# Some annotation files (eg. lift-overs) may
		# included negative coordinates, need to fix		

		push( @{ $bin{$seq_id}{$transcript_id} }, $feature );
	}
	

	return %bin ;
	
}

sub _build_transcript_from_exons_with_seq_id {
	
	my @features = @_;
		
	my $transcript_start = 0;
	my $transcript_end = 0;
	my $transcript_strand = undef;
	my $seq_id = undef;
	my $source_tag = undef;
	my $transcript_id = undef;
	my $primary_tag = undef;
	my $gene_id = undef;

	# All features belonging to the same transcript_id
	# Used to calculate transcript coordinates.
	foreach my $f (@features) {

		my @gvalues = $f->get_tag_values('gene_id');
		$gene_id = shift @gvalues ;
		
		my @tvalues = $f->get_tag_values('transcript_id');
		$transcript_id = shift @tvalues ;
				
		# CDS never contain more information than exons, skip
		#if ($f->primary_tag eq 'exon') {
			$transcript_strand = $f->strand;
			$seq_id = $f->seq_id;
			$source_tag = $f->source_tag;
			
			if ($transcript_start == 0) {
				$transcript_start = $f->start;
				$transcript_end = $f->end;
				$transcript_strand = $f->strand;
				$seq_id = $f->seq_id;
				$source_tag = $f->source_tag;
			}
			
			if ($transcript_start > $f->start) {
				$transcript_start = $f->start ;
			}
			
			if ($transcript_end < $f->end) {
				$transcript_end = $f->end ;
			}
		#} 
					
	} # end transcript features

	
	## THIS NEEDS CHECKING!
	# We assume that EnsEMBL source_tags comply with SO terms - except 'protein_coding'
	
	if ($source_tag =~ /.*RNA.*/) {
		$primary_tag = $source_tag ;
	} else {
		$primary_tag = "mRNA" ;
	}	

	my $t_feature = Bio::SeqFeature::Generic->new(-start => $transcript_start, -primary_tag => $primary_tag , -frame => '.' , -end => $transcript_end, -strand => $transcript_strand , -seq_id => $seq_id, -source_tag => $source_tag, -tag => { 'ID' => $transcript_id , 'Parent' => $gene_id }) ;
	
	#$t_feature = append_attributes($t_feature, $f);

	return $t_feature;
	
}

sub _build_gene_from_transcripts_with_seq_id {
	
	my @transcripts = @_ ;
	
	# Define the gene container parameters:
	my $gene_start = 0;
	my $gene_end = 0;
	my $gene_strand = undef;
	my $gene_id = undef;
	my $contig = undef;
	my $source_tag = undef;
	my $source_tag = undef ;
	my $seq_id = undef;
	
	foreach my $t_feature (@transcripts) {
		
		$source_tag = $t_feature->source_tag;
		$seq_id = $t_feature->seq_id;
		
		my @gvalues = $t_feature->get_tag_values('Parent');
		$gene_id = shift @gvalues ;
	
		# Re-size the gene container...
		if ($gene_start == 0) {
			$gene_start = $t_feature->start;
			$gene_end = $t_feature->end;
			$gene_strand = $t_feature->strand;
			$contig = $t_feature->seq_id;
		}	
		if ($gene_start > $t_feature->start) {
			$gene_start = $t_feature->start;
		}

		if ($gene_end < $t_feature->end) {
			$gene_end = $t_feature->end;
		} # end gene resize
		
	}
	
	my $gene_feature = Bio::SeqFeature::Generic->new(-start => $gene_start, -primary_tag => 'gene' , -frame => '.', -end => $gene_end, -strand => $gene_strand , -seq_id => $contig, -source_tag => $source_tag, -tag => { "ID" => $gene_id }) ;
	
	#$gene_feature = append_attributes($gene_feature, $t_feature);

	return $gene_feature;
	
}

1;
