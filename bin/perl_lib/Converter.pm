#!/usr/bin/perl -w

package Converter;

use strict;
use Bio::Tools::GFF;
use FindBin;
use lib "$FindBin::Bin/Converter";
use Converter::EnsEMBL2GFF3 ;

=head1 SYNOPSIS



=head1 DESCRIPTION

	A library to convert various annotation files
	to GFF3 format. This is the core file in which we 
	specify all required resources. 
	
=cut	





1;

