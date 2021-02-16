package EPrints::Plugin::Screen::Report::User::Orcid;

use EPrints::Plugin::Screen::Report::User;
our @ISA = ( 'EPrints::Plugin::Screen::Report::User' );

use strict;

sub new
{
        my( $class, %params ) = @_;

        my $self = $class->SUPER::new( %params );

        $self->{datasetid} = 'user';
        $self->{custom_order} = '-name';
        $self->{appears} = [];
        $self->{report} = 'orcid';
        $self->{disable} = 1;
        $self->{show_compliance} = 0;

        $self->{labels} = { outputs => "users" };

        $self->{exportfields} = {
                    orcid_user => [ qw(
                            userid
                            username
                            email
                            name
                            orcid
                    )],
            };

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
