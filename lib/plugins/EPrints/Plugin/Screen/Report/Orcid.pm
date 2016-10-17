package EPrints::Plugin::Screen::Report::Orcid;

use EPrints::Plugin::Screen::Report;
our @ISA = ( 'EPrints::Plugin::Screen::Report' );

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

sub ajax_user
{
        my( $self ) = @_;

        my $repo = $self->repository;

        my $json = { data => [] };

        $repo->dataset( "user" )
        ->list( [$repo->param( "user" )] )
        ->map(sub {
                (undef, undef, my $user) = @_;

                return if !defined $user; # odd

                my $frag = $user->render_citation_link;
                push @{$json->{data}}, {
                        datasetid => $user->dataset->base_id,
                        dataobjid => $user->id,
                        summary => EPrints::XML::to_string( $frag ),
#                       grouping => sprintf( "%s", $user->value( SOME_FIELD ) ),
                        problems => [ $self->validate_dataobj( $user ) ],
                };
        });
        print $self->to_json( $json );
}

sub validate_dataobj
{

	my( $self, $user ) = @_;

        my $repo = $self->{repository};

        my @problems;

	#is there an ORCID?
	if( !$user->is_set( "orcid" ) )
	{
		push @problems, $repo->phrase( "orcid_missing" );		
	}

	return @problems;
}
