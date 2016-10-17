package EPrints::MetaField::Orcid;

use strict;
use warnings;

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

        my @problems = $session->get_repository->call(
                "validate_field",
                $self,
                $value,
                $session );

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
