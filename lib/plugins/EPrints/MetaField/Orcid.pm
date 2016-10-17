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

	foreach my $orcid ( @{$value} )
	{

		#get orcid digits
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
	}

        $self->{repository}->run_trigger( EPrints::Const::EP_TRIGGER_VALIDATE_FIELD(),
                field => $self,
                dataobj => $object,
                value => $value,
                problems => \@problems,
        );

        return @problems;
}


######################################################################
1;
