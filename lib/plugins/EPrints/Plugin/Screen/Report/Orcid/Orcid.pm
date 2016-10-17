package EPrints::Plugin::Screen::Report::Orcid::Orcid;

use EPrints::Plugin::Screen::Report::Orcid;
our @ISA = ( 'EPrints::Plugin::Screen::Report::Orcid' );

use strict;

sub new
{
        my( $class, %params ) = @_;

        my $self = $class->SUPER::new( %params );

        $self->{report} = 'orcid';
	
        return $self;
}

