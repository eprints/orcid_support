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
$c->{plugins}{"Screen::Report::Orcid::Orcid"}{params}{disable} = 0;

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
	@{$c->{fields}->{user}} = (@{$c->{fields}->{user}}, (
        	{
                	'name' => 'orcid',
	                'type' => 'orcid'
        	}
	));
}

#---EPrints---#
#define the eprint fields we want to add an orcid to here... then run epadmin --update
#$c->{orcid}->{eprint_fields} = ['creators', 'editors'];
$c->{orcid}->{eprint_fields} = [];

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
                                type => 'orcid',
                                input_cols => 19,
                                allow_null => 1,
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


