#Adapted from John Salter's work at: https://wiki.eprints.org/w/ORCID#Exposing_the_ORCID_in_RIOXX 
$c->{rioxx2_value_author} = sub {
	my( $eprint ) = @_;
 

    my $session = $eprint->{session};
    my $orcid_domain = $session->config( 'orcid_support', 'orcid_domain' );

	my @authors;
	for( @{ $eprint->value( "creators" ) } )
	{	
		my $id = $_->{orcid};
		$id = EPrints::ORCID::Utils::get_normalised_orcid( $id ); 
		if( $id ) 
		{
			push @authors, {
				author => EPrints::Utils::make_name_string( $_->{name} ),
				id => "https://" . $orcid_domain . "/" . $id
			};
		} 
		else
		{
			push @authors, {
				author => EPrints::Utils::make_name_string( $_->{name} ),
			};
		}
	}
 
	#NB If your corp_creators has DOIs or ISNIs for the entries, a similar method could be used to include these here.
	foreach my $corp ( @{ $eprint->value( "corp_creators" ) } )
	{
		my $entry = {};
	        $entry->{name} = $corp;
        	push @authors, { author => $corp };
	}
   
	return \@authors;
};
