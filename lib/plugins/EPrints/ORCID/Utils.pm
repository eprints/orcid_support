package EPrints::ORCID::Utils;

use strict;

sub get_normalised_orcid
{
	my( $value ) = @_;

	# what could a user try to search with:
	# Full URL: http://orcid.org/0000-1234-1234-123X
	# Full URL: https://orcid.org/0000-1234-1234-123X
	# Namespaced: orcid.org/0000-1234-1234-123X
	# or            : orcid:0000-1234-1234-123X
	# or value      : 0000-1234-1234-123X
	# or even       : 000012341234123X
	# ...?!
	#
	# The RegExp could be something horrible like:
	# m#^(?:\s*(?:https?:\/\/)?orcid(?:\.org\/|:))?(\d{4}\-?\d{4}\-?\d{4}\-?\d{3}(?:\d|X))(?:\s*)$# )
	# but I think using a word boundary before the ORCID itself is cleaner and just as good...
	#
	
	if( $value =~ m/\b(\d{4})\-?(\d{4})\-?(\d{4})\-?(\d{3}(?:\d|X))/ )
        {
		return "$1-$2-$3-$4";
	}
	else 
	{
		return 0;
	}
}

1;
