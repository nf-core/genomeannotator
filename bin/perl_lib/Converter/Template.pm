#!/usr/bin/perl -w

package BILS::Converter::Template ;

use base 'BILS::Converter';

=head1 SYNOPSIS


=head1 DESCRIPTION

	A library to convert <Source file> to valid GFF3.
	Inherits from BILS::Converter
	
=cut	

# MAKE SURE TO 'use' this file in Coverter.pm for automatic loading. 

sub new {

	my ($self, $file) = @_  ;
	my @answer = (); # An array of Bio::SeqFeature::Generic objects, to be returned for output.
	
	# Do something with the file
	
	my $gtfio = Bio::Tools::GFF->new(-file => $file, -gff_version => 2.5); # Change to appropriate input format
	
	# Iterate over the features and fix them + build missing features (e.g. gene). Push results into @answer
	while( my $feature = $gtfio->next_feature()) {
		
		
		
	} # end GTFIO
	

	# Return an array of GFF3 compliant Bio::SeqFeature::Generic objects
	
	$gtfio->close;
	
	return \@answer ;
	
}


1;