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
		        if( EPrints::Utils::is_set( $_->{name} ) && $_->{name} eq "orcid" )
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
		}
	}	
}

#automatic update of eprint creator field
$c->add_dataset_trigger( 'eprint', EPrints::Const::EP_TRIGGER_BEFORE_COMMIT, sub
{
        my( %args ) = @_;
        my( $repo, $eprint, $changed ) = @args{qw( repository dataobj changed )};

	return unless $eprint->dataset->has_field( "creators_orcid" );
	my $creators = $eprint->get_value('creators');
	my @new_creators;
	my $update = 0;

	foreach my $c (@{$creators})
	{
        	my $new_c = $c;

	        #get id and user profile
                my $email = $c->{id};
                $email = lc($email) if defined $email;
                my $user = EPrints::DataObj::User::user_with_email($eprint->repository, $email);
		if( $user )
	        {
        	        if( EPrints::Utils::is_set( $user->value( 'orcid' ) ) ) #user has an orcid
                	{
                        	if( !EPrints::Utils::is_set( $c->{orcid} ) ) #creator already has an orcid
                        	{
					 #set the orcid
					 $update = 1;
					 $new_c->{orcid} = $user->value( 'orcid' );
				}
			}
		}
  		push( @new_creators, $new_c );
	}
	if( $update )
	{
		$eprint->set_value("creators", \@new_creators);
	}

	
}, priority => 50 );

#automatic update of eprint editor field
$c->add_dataset_trigger( 'eprint', EPrints::Const::EP_TRIGGER_BEFORE_COMMIT, sub
{
        my( %args ) = @_;
        my( $repo, $eprint, $changed ) = @args{qw( repository dataobj changed )};

	return unless $eprint->dataset->has_field( "editors_orcid" );
	my $editors = $eprint->get_value('editors');
	my @new_editors;
	my $update = 0;

	foreach my $e (@{$editors})
	{
        	my $new_e = $e;

	        #get id and user profile
                my $email = $e->{id};
                $email = lc($email) if defined $email;
                my $user = EPrints::DataObj::User::user_with_email($eprint->repository, $email);
		if( $user )
	        {
        	        if( EPrints::Utils::is_set( $user->value( 'orcid' ) ) ) #user has an orcid
                	{
                        	if( !EPrints::Utils::is_set( $e->{orcid} ) ) #creator already has an orcid
                        	{
					 #set the orcid
					 $update = 1;
					 $new_e->{orcid} = $user->value( 'orcid' );
				}
			}
		}
  		push( @new_editors, $new_e );
	}
	if( $update )
	{
		$eprint->set_value("editors", \@new_editors);
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
 
	my $creators = $value->[0];
 
	foreach my $i (0..$#$creators)
	{
 
		my $creator = @$creators[$i];
 
		if( $i > 0 )
		{
			#not first item (or only one item)
			if( $i == $#$creators )
			{
				#last item
				$r->appendChild( $session->make_text( " and " ) );
			}
			else
			{
			        $r->appendChild( $session->make_text( ", " ) );
			}
		}
 
		my $person_span = $session->make_element( "span", "class" => "person" );
		$person_span->appendChild( $session->render_name( $creator->{name} ) );
 
		my $orcid = $creator->{orcid};
		if( defined $orcid && $orcid =~ m/^(?:orcid.org\/)?(\d{4}\-\d{4}\-\d{4}\-\d{3}(?:\d|X))$/ )
		{
			my $orcid_link = $session->make_element( "a", 
				"class" => "orcid",
				"href" => "https://orcid.org/$1",
				"target" => "_blank",
			 );
			$orcid_link->appendChild( $session->make_element( "img", "src" => "/images/orcid_16x16.png" ) );

			my $orcid_span = $session->make_element( "span", "class" => "orcid-tooltip" );
	
			$orcid_span->appendChild( $session->make_text( "ORCID: " ) );
			$orcid_span->appendChild( $session->make_text( $1 ) );
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
