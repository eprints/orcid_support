package EPrints::Plugin::Screen::Report::Orcid::EditorsOrcid;

use EPrints::Plugin::Screen::Report::Orcid;

our @ISA = ( 'EPrints::Plugin::Screen::Report::Orcid' );

use strict;

sub new
{
        my( $class, %params ) = @_;

        my $self = $class->SUPER::new( %params );

        $self->{datasetid} = 'archive';
        $self->{custom_order} = '-title/editors_name';
        $self->{report} = 'orcid-editors';

	$self->{show_compliance} = 0;

	$self->{labels} = {
                outputs => "eprints"
        };


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

                        if( $eprint->is_set("editors_orcid") )
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

        foreach my $editor( @{ $eprint->value( "editors" ) } )
        {
                if( EPrints::Utils::is_set( $editor->{orcid} ) )
                {
                        push @bullets, EPrints::XML::to_string( $repo->html_phrase( "contributor_with_orcid", contributor => $repo->xml->create_text_node(EPrints::Utils::make_name_string( $editor->{name} ) ), orcid => $repo->xml->create_text_node( $editor->{orcid} ) ) );
                }
                else
                {
                        push @bullets, EPrints::XML::to_string( $repo->html_phrase( "contributor_no_orcid", contributor => $repo->xml->create_text_node(EPrints::Utils::make_name_string( $editor->{name} ) ) ) );
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
