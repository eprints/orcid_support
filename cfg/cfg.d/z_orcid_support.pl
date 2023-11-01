=pod

=head1 Orcid Support

ORCID Support Plugin

2016 EPrints Services, University of Southampton

=head2 Changes

0.0.1 Will Fyson <rwf1v07@soton.ac.uk>

Initial version

=cut

use EPrints::ORCID::Utils;

#Enable the plugin!
$c->{plugins}{"Orcid"}{params}{disable} = 0;
$c->{plugins}{"Screen::Report::Orcid::UserOrcid"}{params}{disable} = 0;
$c->{plugins}{"Screen::Report::Orcid::AllUsersOrcid"}{params}{disable} = 0;
$c->{plugins}{"Screen::Report::Orcid::CreatorsOrcid"}{params}{disable} = 0;
$c->{plugins}{"Screen::Report::Orcid::EditorsOrcid"}{params}{disable} = 0;
$c->{plugins}{"Export::Report::CSV::CreatorsOrcid"}{params}{disable} = 0;
$c->{plugins}{"Export::Report::CSV::EditorsOrcid"}{params}{disable} = 0;

#---Users---#
#add orcid field to the user profile's
#but checking first to see if the field is already present in the user dataset before adding it
my $orcid_present = 0;
for(@{$c->{fields}->{user}})
{
    if( $_->{name} eq "orcid" )
    {
        $orcid_present = 1
    }
}
if( !$orcid_present )
{
    @{$c->{fields}->{user}} = ( @{$c->{fields}->{user}}, (
    {
        'name' => 'orcid',
        'type' => 'orcid'
    }
    ));
}

#---EPrints---#
# define the eprint fields we want to add an orcid to here... then run epadmin --update
$c->{orcid}->{eprint_fields} = ['creators', 'editors'];

# add orcid as a subfield to appropriate eprint fields
foreach my $field( @{$c->{fields}->{eprint}} )
{
    if( grep { $field->{name} eq $_ } @{$c->{orcid}->{eprint_fields}} )
    {
        # check if field already has an orcid subfield
        $orcid_present = 0;
        for( @{$field->{fields}} )
        {
            if( EPrints::Utils::is_set( $_->{sub_name} ) && $_->{sub_name} eq "orcid" )
            {
                $orcid_present = 1;
                last;
            }
        }

        # add orcid subfield
        if( !$orcid_present )
        {
            @{$field->{fields}} = ( @{$field->{fields}}, (
            {
                sub_name => 'orcid',
                type => 'orcid',
                input_cols => 19,
                allow_null => 1,
            }
            ));
        }
    }
}

#automatic update of eprint contributor fields ($c->{orcid}->{eprint_fields})
$c->add_dataset_trigger( 'eprint', EPrints::Const::EP_TRIGGER_BEFORE_COMMIT, sub
{
    my( %args ) = @_;
    my( $repo, $eprint, $changed ) = @args{qw( repository dataobj changed )};

    foreach my $role ( @{$c->{orcid}->{eprint_fields}} )
    {
        return unless $eprint->dataset->has_field( $role."_orcid" );
        my $contributors = $eprint->get_value( "$role" );
        my @new_contributors;
        my $update = 0;

        foreach my $c ( @{$contributors} )
        {
            my $new_c = $c;

            #get id and user profile
            my $email = $c->{id};
            $email = lc( $email ) if defined $email;
            my $user = EPrints::DataObj::User::user_with_email( $eprint->repository, $email );
            if( $user )
            {
                #set the orcid if the user has one and the contributor does not
                if( ( EPrints::Utils::is_set( $user->value( 'orcid' ) ) ) && !(EPrints::Utils::is_set( $c->{orcid} ) ) )
                {
                    $update = 1;
                    $new_c->{orcid} = $user->value( 'orcid' );
                }
            }
            push( @new_contributors, $new_c );
        }
        if( $update )
        {
            $eprint->set_value( "$role", \@new_contributors );
        }
    }
}, priority => 50 );


#Rendering ORCIDs
{
package EPrints::Script::Compiled;
use strict;

sub run_people_with_orcids
{
    my( $self, $state, $value ) = @_;

    my $session = $state->{session};
    my $r = $state->{session}->make_doc_fragment;

    my $contributors = $value->[0];
    my $field = $value->[1];

    my $f = $field->get_property( "fields_cache" );
    my $browse_links = {};
    my $views = $session->config( "browse_views" );

    foreach my $sub_field ( @{$f} )
    {
        if( defined $sub_field->{browse_link} )
        {
            my $linkview;
            foreach my $view ( @{$views} )
            {
                $linkview = $view if( $view->{id} eq $sub_field->{browse_link} );
            }
            $browse_links->{$sub_field->property("sub_name")}->{view} = $linkview;
            $browse_links->{$sub_field->property("sub_name")}->{field} = $sub_field;
        }
    }

    foreach my $i ( 0..$#$contributors )
    {
        my $contributor = @$contributors[$i];
        my $url = $session->config( "rel_path" );

        my $contributors = $value->[0];
	my $phraseid = "lib/metafield:join_orcid";

	# don't 'join' the first person
	if( $i > 0 )
	{
		#if we're the last person
		if( $i == $#$creators && $session->get_lang->has_phrase( "$phraseid.last", $session ) )
		{
			$phraseid .= ".last";
		}
		elsif( $i == 1 && $session->get_lang->has_phrase( "$phraseid.first", $session ) )
		{
			# this is the 'first joiner' rather than the first author
			$phraseid .= ".first";
		}

		# add the phrase to the existing elements - before 'this person' is added
		$r->appendChild( $session->html_phrase( $phraseid ) );
	}

        my $person_span = $session->make_element( "span", "class" => "person" );

        # only looking for browse_link in the name sub field for now... 
        if( defined( $browse_links->{name} ) )
        {
            my $linkview = $browse_links->{name}->{view};
            my $sub_field = $browse_links->{name}->{field};
            my $link_id = $sub_field->get_id_from_value( $session, $contributor->{name} );

            if(
                ( defined $linkview->{fields} && $linkview->{fields} =~ m/,/ ) ||
                ( defined $linkview->{menus} && scalar(@{$linkview->{menus}}) > 1 )
            )
            {
                # has sub pages
                $url .= "/view/".$sub_field->{browse_link}."/".
                EPrints::Utils::escape_filename( $link_id )."/";
            }
            else
            {
                # no sub pages
                $url .= "/view/".$sub_field->{browse_link}."/".
                EPrints::Utils::escape_filename( $link_id ).
                ".html";
            }
            my $a = $session->render_link( $url );
            $a->appendChild( $session->render_name( $contributor->{name} ) );
            $person_span->appendChild( $a );
        }
        else
        {
            $person_span->appendChild( $session->render_name( $contributor->{name} ) );
        }

 
        my $orcid = $contributor->{orcid};
        my $uri = "";
        $uri = $session->get_request->uri if defined $session->get_request;
        if( $uri !~ m/exportview/ && $uri !~ m!/export_! && $uri !~ m!/cgi/export/! && defined $orcid && $orcid =~ m/^(?:orcid.org\/)?(\d{4}\-\d{4}\-\d{4}\-\d{3}(?:\d|X))$/ )
        {
            my $orcid_link = $session->make_element( "a",
                "class" => "orcid",
                "href" => "https://orcid.org/$1",
                "target" => "_blank",
            );
            $orcid_link->appendChild( $session->make_element( "img", "src" => "/images/orcid_id.svg", "class" => "orcid-icon", "alt" => "ORCID logo" ) );

            my $orcid_span = $session->make_element( "span", "class" => "orcid-tooltip" );

            $orcid_span->appendChild( $session->make_text( "ORCID: " ) );
            $orcid_span->appendChild( $session->make_text( "https://orcid.org/$1" ) );
            $orcid_link->appendChild( $orcid_span );

            $person_span->appendChild( $session->make_text( " " ) );
            $person_span->appendChild( $orcid_link );

            $person_span->setAttribute( "class", "person orcid-person" );
        }
        $r->appendChild( $person_span );
    }
    return [ $r, "XHTML" ];
}

}
