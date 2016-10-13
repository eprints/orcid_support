#Enable the plugin!
$c->{plugins}{"Orcid"}{params}{disable} = 0;

#---Users---#

#Add orcid field to the user profile's
@{$c->{fields}->{user}} = (@{$c->{fields}->{user}}, (
        {
                'name' => 'orcid',
                'type' => 'text'
        }
));

#---EPrints---#

#define the eprint fields we want to add an orcid to
$c->{orcid}->{eprint_fields} = ['creators'];

#add orcid as a subfield to appropriate eprint fields
my @oldFields = @{$c->{fields}->{eprint}};
my @newFields = ();
foreach my $field( @oldFields )
{
        if($field->{name} ~~ $c->{orcid}->{eprint_fields})
        {
                my @fields = @{$field->{fields}};
                push @fields,
                        {
                                sub_name => 'orcid',
                                type => 'text',
                                input_cols => 19,
                                allow_null => 1,
                                render_value => sub {

                                        my( $session, $field, $value ) = @_;
                                        my $orcidDiv = $session->make_element( "div" );
                                        foreach my $orcid (@$value)
                                        {
                                                my $url = "http://orcid.org/$orcid";

                                                my $orcidLink = $session->make_element( "span" );
                                                $orcidDiv->appendChild( $orcidLink );
                                                my $link = $session->render_link( $url );
                                                $link->appendChild( $session->make_text( $orcid ) );
                                                $orcidLink->appendChild( $link );
                                                $orcidDiv->appendChild( $session->make_element( "br" ) );
                                        }
                                        return $orcidDiv;
                                },
                        };
                $field->{fields} = \@fields;
                push @newFields, $field;
        }
        else
        {
                push @newFields, $field;
        }
}
$c->{fields}->{eprint} = \@newFields;


