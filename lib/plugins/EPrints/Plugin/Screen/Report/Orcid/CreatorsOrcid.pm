package EPrints::Plugin::Screen::Report::Orcid::CreatorsOrcid;

use EPrints::Plugin::Screen::Report::Orcid;

our @ISA = ( 'EPrints::Plugin::Screen::Report::Orcid' );

use strict;

sub new
{
        my( $class, %params ) = @_;

        my $self = $class->SUPER::new( %params );

        $self->{datasetid} = 'archive';
        $self->{custom_order} = '-title/creators_name';
        $self->{report} = 'orcid-creators';

        return $self;
}

sub items
{
        my( $self ) = @_;

	my $list = $self->SUPER::items();

        if( defined $list )
        {
                my @ids = ();

                $list->map(sub{
                        my($session, $dataset, $eprint) = @_;

                        if( $eprint->is_set("creators_orcid") )
                        {
                                push @ids, $eprint->id;
                        }
                });
		my $ds = $self->{session}->dataset( $self->{datasetid} );
                my $results = $ds->list(\@ids);
                return $results;

        }
        # we can't return an EPrints::List if {dataset} is not defined
        return undef;
}

sub ajax_eprint
{
        my( $self ) = @_;

        my $repo = $self->repository;

        my $json = { data => [] };

        $repo->dataset( "eprint" )
        ->list( [$repo->param( "eprint" )] )
        ->map(sub {
                (undef, undef, my $eprint) = @_;

                return if !defined $eprint; # odd

                my $frag = $eprint->render_citation_link;
                push @{$json->{data}}, {
                        datasetid => $eprint->dataset->base_id,
                        dataobjid => $eprint->id,
                        summary => EPrints::XML::to_string( $frag ),
#                       grouping => sprintf( "%s", $user->value( SOME_FIELD ) ),
                        problems => [ $self->validate_dataobj( $eprint ) ],
                        bullets => [ $self->bullet_points( $eprint ) ],
                };
        });
        print $self->to_json( $json );
}

#bullet points to display when record is compliant
sub bullet_points
{
        my( $self, $eprint ) = @_;

        my $repo = $self->{repository};

        my @bullets;

        foreach my $creator( @{ $eprint->value( "creators" ) } )
        {
                if( EPrints::Utils::is_set( $creator->{orcid} ) )
                {
                        push @bullets, EPrints::XML::to_string( $repo->html_phrase( "creator_with_orcid", creator => $repo->xml->create_text_node(EPrints::Utils::make_name_string( $creator->{name} ) ), orcid => $repo->xml->create_text_node( $creator->{orcid} ) ) );
                }
                else
                {
                        push @bullets, EPrints::XML::to_string( $repo->html_phrase( "creator_no_orcid", creator => $repo->xml->create_text_node(EPrints::Utils::make_name_string( $creator->{name} ) ) ) );
                }
        }

        return @bullets;
}

sub validate_dataobj
{

        my( $self, $eprint ) = @_;

        my $repo = $self->{repository};

        my @problems;

        return @problems;
}

                       
