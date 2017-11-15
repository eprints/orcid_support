package EPrints::MetaField::Orcid;

use strict;
use warnings;
use Data::Dumper;
use EPrints::MetaField::Id;

BEGIN {
        our( @ISA );
        @ISA = qw( EPrints::MetaField::Id );
}

sub get_basic_input_elements
{
        my( $self, $session, $value, $basename, $staff, $obj ) = @_;

        my $maxlength = $self->get_max_input_size;
        my $size = ( $maxlength > $self->{input_cols} ?
                                        $self->{input_cols} :
                                        $maxlength );


        my $input;
        if( defined $self->{render_input} )
        {
                $input = $self->call_property( "render_input",
                        $self,
                        $session,
                        $value,
                        $self->{dataset},
                        $staff,
                        undef,
                        $obj,
                        $basename );
        }
        else
        {
                my @classes = (
                        "ep_form_text",
                );
                if( defined($self->{dataset}) )
                {
                        push @classes,
                                join('_', 'ep', $self->{dataset}->base_id, $self->name);
                }
		if( $session->config( 'orcid_support_advance', 'disable_input' ) )
		{
                	$input = $session->render_noenter_input_field(
                        	class=> join(' ', @classes),
	                        name => $basename,
                	        id => $basename,
         	                value => $value,
	                        size => $size,
                        	maxlength => $maxlength,
				readonly => "true" );
		}
		else
		{
 			$input = $session->render_noenter_input_field(
                        	class=> join(' ', @classes),
	                        name => $basename,
                	        id => $basename,
         	                value => $value,
	                        size => $size,
                        	maxlength => $maxlength );
		}
        }

        return [ [ { el=>$input } ] ];
}


sub render_single_value
{
	my( $self, $session, $value ) = @_;
        
       	my $url = "http://orcid.org/$value";
 
        my $link = $session->render_link( $url, "_blank" );
	$link->appendChild( $session->make_element( "img", src => "/images/orcid_16x16.png", class => "orcid-icon" ) );
        $link->appendChild( $session->make_text( "orcid.org/$value" ) );
        
        return $link;
}

sub validate
{
        my( $self, $session, $value, $object ) = @_;

	my @problems;

	return @problems unless EPrints::Utils::is_set( $value );

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

	return @problems unless EPrints::Utils::is_set( $orcid );

	my $size = length( $orcid );
	if( $size == 19 )
	{
		$orcid =~ s/-//g;
	        my @digits = split //, $orcid;

                #generate check digit
                my $total = 0;
                for my $i (0 .. (scalar @digits - 2))
                {
                        $total = ($total + $digits[$i]) * 2;
                }
                my $rem = $total % 11;
                my $res = (12 - $rem) % 11;
                $res = $res == 10 ? "X" : $res;
                if( ($res eq 'X' && $digits[15] ne 'X') || ($res =~ /\d/ && $res != $digits[15]) )
                {
                        push @problems, $session->html_phrase( "validate:invalid_orcid_checksum" );
                }
        }
        else
        {
                push @problems, $session->html_phrase( "validate:invalid_orcid_format" );
        }
	
	return @problems;
}

sub from_search_form
{
	my( $self, $session, $prefix ) = @_;

	my $val = $session->param( $prefix );
	return $val unless EPrints::Utils::is_set( $val );

	if( $val = EPrints::ORCID::Utils::get_normalised_orcid( $val ) )
	{
		return(
               		"$val", #orcid matched in capturing group above
			scalar($session->param( $prefix."_match" )),
			scalar($session->param( $prefix."_merge" ))
		);
	}

	return( undef,undef,undef, $session->html_phrase( "searchfield:orcid_err" ) );
}
######################################################################

1;
