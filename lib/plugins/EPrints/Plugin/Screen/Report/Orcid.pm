package EPrints::Plugin::Screen::Report::Orcid;

use EPrints::Plugin::Screen::Report;
our @ISA = ( 'EPrints::Plugin::Screen::Report' );

use strict;

sub new
{
        my( $class, %params ) = @_;

        my $self = $class->SUPER::new( %params );

        $self->{appears} = [];
        $self->{report} = 'orcid';
        $self->{disable} = 1;

        return $self;
}

sub can_be_viewed
{
        my( $self ) = @_;

        return 1;

        return $self->allow( 'admin' );
}

sub filters
{
        my( $self ) = @_;

        my @filters = @{ $self->SUPER::filters || [] };

        return \@filters;
}

