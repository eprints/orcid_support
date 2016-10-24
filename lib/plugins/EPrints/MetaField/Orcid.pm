package EPrints::MetaField::Orcid;

use strict;
use warnings;
use Data::Dumper;
use EPrints::MetaField::Text;

BEGIN {
        our( @ISA );
        @ISA = qw( EPrints::MetaField::Text );
}

sub render_single_value
{
	my( $self, $session, $value ) = @_;
        
	my $orcidDiv = $session->make_element( "div" );
       	my $url = "http://orcid.org/$value";
        my $orcidLink = $session->make_element( "span" );
        $orcidDiv->appendChild( $orcidLink );
 
        my $link = $session->render_link( $url );
        $link->appendChild( $session->make_text( $value ) );
        $orcidLink->appendChild( $link );
        
        return $orcidDiv;
}

sub validate
{
        my( $self, $session, $value, $object ) = @_;

	my @problems;

	#orcid field may be used in either a array context or as single value
	if( ref($value) eq 'ARRAY' )
	{
		foreach my $orcid (@{$value})
		{
			@problems = validate_orcid( $session, $orcid, @problems );
		}
	}
	else
	{
		@problems = validate_orcid( $session, $value, @problems );
	}

        $self->{repository}->run_trigger( EPrints::Const::EP_TRIGGER_VALIDATE_FIELD(),
                field => $self,
                dataobj => $object,
                value => $value,
                problems => \@problems,
        );

        return @problems;
}

sub validate_orcid
{
	my( $session, $orcid, @problems ) = @_;

	$orcid =~ s/-//g;
        my @digits = split //, $orcid;
        if( scalar @digits == 16 ) #check there are 16 digits...
        {
                #generate check digit
                my $total = 0;
                for my $i (0 .. (scalar @digits - 2))
                {
                        $total = ($total + $digits[$i]) * 2;
                }
                my $rem = $total % 11;
                my $res = (12 - $rem) % 11;
                $res = $res == 10 ? "X" : $res;
                        if( $res != $digits[15] )
                {
                        push @problems, $session->html_phrase( "validate:invalid_orcid" );
                }
        }
        else
        {
                push @problems, $session->html_phrase( "validate:invalid_orcid" );
        }
	
	return @problems;
}

sub from_search_form
{
	my( $self, $session, $prefix ) = @_;

	my $val = $session->param( $prefix );
	return $val unless EPrints::Utils::is_set( $val );

	# what could a user try to search with:
	# Full URL: http://orcid.org/0000-1234-1234-123X
	# Full URL: https://orcid.org/0000-1234-1234-123X
	# Namespaced: orcid.org/0000-1234-1234-123X
	# or		: orcid:0000-1234-1234-123X
	# or value	: 0000-1234-1234-123X
	# or even	: 000012341234123X
	# ...?!
	#
	# The RegExp could be something horrible like:
	# m#^(?:\s*(?:https?:\/\/)?orcid(?:\.org\/|:))?(\d{4}\-?\d{4}\-?\d{4}\-?\d{3}(?:\d|X))(?:\s*)$# )
	# but I think using a word boundary before the ORCID itself is cleaner and just as good...
	#
	if( $val =~ m/\b(\d{4})\-?(\d{4})\-?(\d{4})\-?(\d{3}(?:\d|X))/ )
	{
		return(
               		"$1-$2-$3-$4", #orcid matched in capturing group above
			scalar($session->param( $prefix."_match" )),
			scalar($session->param( $prefix."_merge" ))
		);
	}

	return( undef,undef,undef, $session->html_phrase( "searchfield:orcid_err" ) );
}
######################################################################

1;
