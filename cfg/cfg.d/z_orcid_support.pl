=pod

=head1 ORCID Support

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
######################################################################
#
# EPrints::Script::Compiled
#
######################################################################
#
#
######################################################################

=pod

=head1 NAME

B<EPrints::Script::Compiled> - Namespace for EPrints::Script functions.

=cut

=head1 DESCRIPTION

Additional function being added
to L<EPrints::Script::Compiled>
at the archive level via C<z_orcid_support.pl>
for ORCID support.

=cut

package EPrints::Script::Compiled;
use     strict;
use     feature qw(fc); # Available in Perl 5.16 or higher.
                        # Folds case for UTF-8 / Unicode friendly case insensitive comparisons.
                        # https://perldoc.perl.org/perlfunc#fc

use     Scalar::Util qw(blessed);

=head1 SUBROUTINES

=over

=item run_people_with_orcids(creators);

Synopsis:

    # Use in a citation:
    <epc:print expr="people_with_orcids(creators)"/>

    # Alternatively:
    <epc:print expr="people_with_orcids(editors)"/>

Takes a list of people (creators, editors, etc),
decides whether to display an ORCID,
depending on the context,
and the existence of a valid ORCID for that person,
and if so handles the rendering of names and ORCID numbers and badges.

Returns an anonymous array reference containing
at index 0 an XHTML document fragment (specifically
an L<XML::LibXML::DocumentFragment> object),
and at index 1 the string 'XHTML'
- presumably to identify the nature of what is at index 0.

This subroutine requires additional files:

=over

=item cfg/citations/eprint/orcid_for_coversheet.xml

This file is how the ORCID link should be rendered in coversheet tag context.

=item cfg/citations/eprint/orcid_for_csv.xml

This file is how the ORCID link should be rendered in csv file context.
This only ensures a correct ORCID link.
Additional processing of the citation may still be required
to strip excess white space from the citation overall before use in a csv file.

=item cfg/citations/eprint/orcid_for_email.xml

This file is how the ORCID link should be rendered in email context.

=item cfg/citations/eprint/orcid_for_web.xml

This file is how the ORCID link should be rendered in web page context.

=back

Strings passed from this subroutine...

    # Simplified example - current code isn't exactly like this:
    my  $citation_params = {
        string  =>  'The text that makes up our string',
    };

    my  $xhtml  =   $item->render_citation($citation_name, %{$citation_params});

...should be accessed in the citation as...

    # Within a html/xml/xhtml tag's attribute:
    <tag attribute="{$string.as_string()}"></tag>   # For example only.
                                                    # No such xhtml tag as 'tag'.

    # Or standalone:
    <epc:print expr="$string.as_string()"/>

The C<as_string()> function
may be needed to avoid
the error:
C<[No type for value 'The text that makes up our string' from '$string']>.

For more info on EPScript Functions, see:
L<https://wiki.eprints.org/w/EPScript/Functions>

Should you edit these citation files,
and have the commandline tool C<xmllint>,
then it is recommended you check the files
are valid xml after editing,
by running from the commandline:

    # Individually:

    xmllint orcid_for_coversheet.xml

    xmllint orcid_for_csv.xml

    xmllint orcid_for_email.xml

    xmllint orcid_for_web.xml

    # All at once:

    xmllint orcid_for*.xml

Those examples assume
you are already in the correct directory,
typically C<< /opt/eprints3/archives/archive_name/cfg/citations/eprint >>
where C<archive_name> is the name of your repository folder.

If C<xmllint> concludes your file has no problems,
it will output the file contents.

Web page context is assumed by default,
unless a C<render_citation>,
C<render_citation_link> or C<render_citation_link_staff>
method call is made with the
C<< for_use_in => $value >> argument / option / parameter given,
where C<$value> can be (case insensitive)
C<csv>, C<coversheet>, C<email> or C<web>, as such:
    
    # On an item that can render a citation ($eprint, $user, etc):
    $eprint->render_citation($citation_style, for_use_in => 'email');

This subroutine uses the fc feature, available in Perl version 5.16 and above,
and may need to be altered to run on lower Perl versions.

=back

=cut


sub run_people_with_orcids
{
    my( $self, $state, $value ) =   @_;

    my  $repository             =   $state->{session};
    my  $item                   =   $state->{item};
    my  $for_use_in             =   $state->{for_use_in}?   $state->{for_use_in}:
                                    q{};
    my  $r                      =   $repository->make_doc_fragment;

    
    # Regular Expressions:
    my  $captures_valid_orcid   =   qr!
                                        ^               # Start of string
                                        (?:orcid.org/)? # Optional non-capturing orcid.org/
                                        (?<orcid>       # Start 'orcid' capturing group...
                                            \d{4}\-     # Four digits and a dash
                                            \d{4}\-     # Four digits and a dash
                                            \d{4}\-     # Four digits and a dash
                                            \d{3}       # Three digits
                                            (?:\d|X)    # another digit or the letter X
                                        )               # ...end capturing group.
                                        $               # End of String.
                                    !x;                 # x flag - allow white space and comments as above.
    my  $matches_export_related =   qr!
                                        (               # Start logical group...
                                            exportview  # Matches exportview  
                                            |           # ...or...
                                            export_     # Matches export_
                                            |           # ...or...
                                            cgi/export/ # Matches cgi/export/
                                        )               # ...End logical group.
                                    !x;                 # x flag - allow white space and comments as above.
    my  $matches_yes            =   qr/^(y|yes)$/i;     # case insensitive y or yes and an exact match - no partial matches like yesterday.
                                                        # Originally used to assess a yaml toggle to determine $email_display_setting value.

    # Processing:
    
    my $contributors = $value->[0];
    my $field = $value->[1];

    my $f = $field->get_property( "fields_cache" );
    my $browse_links = {};
    my $views = $repository->config( "browse_views" );

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
        my $url = $repository->config( "rel_path" );

        my $contributors = $value->[0];

        if( $i > 0 )
        {
            # not first item (or only one item)
            if( $i == $#$contributors )
            {
                # last item
                $r->appendChild( $repository->make_text( " and " ) );
            }
            else
            {
                $r->appendChild( $repository->make_text( ", " ) );
            }
        }

        my $person_span = $repository->make_element( "span", "class" => "person" );

        # only looking for browse_link in the name sub field for now... 
        if( defined( $browse_links->{name} ) )
        {
            my $linkview = $browse_links->{name}->{view};
            my $sub_field = $browse_links->{name}->{field};
            my $link_id = $sub_field->get_id_from_value( $repository, $contributor->{name} );

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
            my $a = $repository->render_link( $url );
            $a->appendChild( $repository->render_name( $contributor->{name} ) );
            $person_span->appendChild( $a );
        }
        else
        {
            $person_span->appendChild( $repository->render_name( $contributor->{name} ) );
        }


        # SHOWING ORCID:

        # Initial Values: 
        my  $default_display_setting        =   1;  # 1 to Show ORCIDs by default
                                                    # i.e. if not "for use in" any special context
                                                    # via (for_use_in => 'special context').
                                                    #
                                                    # Set to 0 to prevent showing ORCIDs by default
                                                    # in all contexts except special contexts
                                                    # that defer to their own display setting values.
                                                    # Final decision to show depends on value of $show_orcid variable.

        my  $email_display_setting          =   1;  # Set to 0 to exclude ORCIDs from email flagged contexts.
        my  $coversheet_display_setting     =   1;  # Set to 0 to exclude ORCIDs from coversheet flagged contexts.
        my  $csv_display_setting            =   1;  # Set to 0 to exclude ORCIDs from csv flagged contexts.

        my  $valid_orcid                    =   defined $contributor->{orcid}
                                                && ($contributor->{orcid} =~ $captures_valid_orcid)?    $+{orcid}:
                                                undef;

        my  $uri                            =   defined $repository->get_request?                       $repository->get_request->uri:
                                                q{};

        my  $uri_not_export_related         =   $uri !~ $matches_export_related;

        my  $display_setting                =   (fc $for_use_in) eq (fc 'email')?                       $email_display_setting:
                                                (fc $for_use_in) eq (fc 'coversheet')?                  $coversheet_display_setting:
                                                (fc $for_use_in) eq (fc 'csv')?                         $csv_display_setting:
                                                $default_display_setting; # Fallback.

        my  $show_orcid                     =   $uri_not_export_related
                                                && $valid_orcid
                                                && $display_setting;

        # Processing:                         
        if ($show_orcid)
        {
            # Initial Values:
            my  @static_folder = (
                path                        =>  "static",
                scheme                      =>  "https",
                host                        =>  1,
            );

            my  $static_folder              =   $repository->get_url(@static_folder)->abs($repository->config("base_url"));
            my  $citation_name              =   (fc $for_use_in) eq (fc 'email')?       'orcid_for_email':
                                                (fc $for_use_in) eq (fc 'coversheet')?  'orcid_for_coversheet':
                                                (fc $for_use_in) eq (fc 'csv')?         'orcid_for_csv':
                                                'orcid_for_web'; # default/fallback
            my  $provided_citation_params   =   $state;

            my  $our_overriding_citation_params = {

                # Essentials required:
                item                        =>  $item,
                session                     =>  $repository,
                repository                  =>  $repository,
                in                          =>  'EPrints::Script::Compiled::run_people_with_orcids',

                # Values for use in citations:
                valid_orcid                 =>  $valid_orcid,   # Access in citation as {$valid_orcid.as_string()}
                static_folder               =>  $static_folder, # Access in citation as {$static_folder.as_string()}

            };

            my  $citation_params            =   {
                                                    %{$provided_citation_params},
                                                    %{$our_overriding_citation_params},
                                                };

            # Processing:
            my  $orcid_link                 =   $item->render_citation($citation_name, %{$citation_params});
            my  $valid_orcid_link           =   $orcid_link
                                                && Scalar::Util::blessed($orcid_link)
                                                && $orcid_link->isa('XML::LibXML::DocumentFragment')
                                                && $orcid_link->can('hasChildNodes')
                                                && $orcid_link->hasChildNodes;

            # Output:
            if ($valid_orcid_link) {
                $person_span->appendChild( $repository->make_text( " " ) );
                $person_span->appendChild( $orcid_link );

                $person_span->setAttribute( "class", "person orcid-person" );
            };
        }
        
        # Output per contributor:
        $r->appendChild( $person_span );
    }

    # Final output:
    return [ $r, "XHTML" ];
}

}

=head1 COPYRIGHT

=for COPYRIGHT BEGIN

Copyright 2024 University of Southampton.
EPrints 3.4 is supplied by EPrints Services.

http://www.eprints.org/eprints-3.4/

=for COPYRIGHT END

=head1 LICENSE

=for LICENSE BEGIN

This file is part of EPrints 3.4 L<http://www.eprints.org/>.

EPrints 3.4 and this file are released under the terms of the
GNU Lesser General Public License version 3 as published by
the Free Software Foundation unless otherwise stated.

EPrints 3.4 is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with EPrints 3.4.
If not, see L<http://www.gnu.org/licenses/>.

=for LICENSE END

=cut
