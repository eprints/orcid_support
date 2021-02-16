package EPrints::Plugin::Screen::Report::EPrint::OrcidEPrint;

use EPrints::Plugin::Screen::Report::EPrint;
our @ISA = ( 'EPrints::Plugin::Screen::Report::EPrint' );

use strict;

sub new
{
        my( $class, %params ) = @_;

        my $self = $class->SUPER::new( %params );

        $self->{appears} = [];
        $self->{report} = 'orcid';
        $self->{disable} = 1;
        $self->{show_compliance} = 0;
        $self->{datasetid} = 'archive';
        $self->{custom_order} = '-title/creators_name';
        $self->{labels} = { outputs => "eprints" };

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
