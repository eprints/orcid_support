=pod

=head1 Orcid Support

ORCID Support Plugin

2016 EPrints Services, University of Southampton

=head2 Changes

0.0.1 Will Fyson <rwf1v07@soton.ac.uk>

Initial version

=cut

use EPrints::ORCID::Utils;
use Data::Dumper;

#Enable the plugin!
$c->{plugins}{"Orcid"}{params}{disable} = 0;
$c->{plugins}{"Screen::Report::Orcid::UserOrcid"}{params}{disable} = 0;
$c->{plugins}{"Screen::Report::Orcid::AllUsersOrcid"}{params}{disable} = 0;
$c->{plugins}{"Screen::Report::Orcid::CreatorsOrcid"}{params}{disable} = 0;
$c->{plugins}{"Export::Report::CSV::CreatorsOrcid"}{params}{disable} = 0;

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
$c->{orcid}->{eprint_fields} = ['creators', 'editors'];

#add orcid as a subfield to appropriate eprint fields
foreach my $field( @{$c->{fields}->{eprint}} )
{
	if( grep { $field->{name} eq $_ } @{$c->{orcid}->{eprint_fields}})
        {
		#check if field already has an orcid subfield
		$orcid_present = 0;
		for(@{$field->{fields}})
		{
		        if( $_->{name} eq "orcid" )
		        {
		                $orcid_present = 1;
				last;
		        }
		}
		
		#add orcid subfield
		if( !$orcid_present )
		{
			@{$field->{fields}} = (@{$field->{fields}}, (
				{
                                	sub_name => 'orcid',
	                                type => 'orcid',
        		                input_cols => 19,
                        	 	allow_null => 1,
	                        }
			));
		
			#add a new render method to the name field
			foreach my $f( @{$field->{fields}})
			{
				if( $f->{sub_name} eq 'name' && !EPrints::Utils::is_set( $f->{render_value} ) )
				{
					$f->{render_value} = 'render_orcid_link';			
				}
			}
		}
	}	
}

#ORCID rendering
$c->{render_orcid_link} = sub
{
	my( $session, $field, $value, $alllangs, $nolink, $object ) = @_;

	my $pvals = $object->get_value( $field->{parent_name} );

	return $field->render_value_actual( $session, $value, $alllangs, $nolink, $object ) if scalar( @$value ) != scalar( @$pvals );

	my $html = $session->make_doc_fragment();

	for(my $i=0; $i<scalar(@$value); ++$i )
        {
                my $sv = $value->[$i];
                my $pv = $pvals->[$i]; # parent value
		unless( $i == 0 )
                {
                        my $phrase = "lib/metafield:join_".$field->get_type;
                        my $basephrase = $phrase;
                        if( $i == scalar(@$value)-1 && $session->get_lang->has_phrase( $basephrase.".last" ) )
                        {
                                $phrase = $basephrase.".last";
                        }
                        $html->appendChild( $session->html_phrase( $phrase ) );
                }

		# render internal names in span so they can be highlighted using css
		my $frag = $session->make_doc_fragment;
                my $putnamehere = $frag;
		if( EPrints::Utils::is_set( $pv->{orcid} ) )
                {
			my $link = $session->make_element( "a", href => "http://orcid.org/".$pv->{orcid}, target => "_blank" );		
			$putnamehere = $link;
		}

		$putnamehere->appendChild(
                        $field->render_value_no_multiple(
                        $session,
                        $sv,
                        $alllangs,
                        $nolink,
                        $object ) );


		$html->appendChild( $putnamehere );
	}
	return $html;
}
