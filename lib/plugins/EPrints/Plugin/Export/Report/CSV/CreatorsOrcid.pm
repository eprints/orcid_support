package EPrints::Plugin::Export::Report::CSV::CreatorsOrcid;

use EPrints::Plugin::Export::Report::CSV;
our @ISA = ( "EPrints::Plugin::Export::Report::CSV" );

use strict;

sub new
{
        my( $class, %params ) = @_;

        my $self = $class->SUPER::new( %params );

        $self->{name} = "CSV";
        $self->{accept} = [ 'report/orcid-creators', ];
        $self->{advertise} = 1;
        return $self;
}

sub output_list
{
        my( $plugin, %opts ) = @_;

        my @titles = ("EPrintID", "Creators Name", "Creators ID", "ORCID");

        print join( ",", @titles );
        print "\n";

        $opts{list}->map( sub {
                my( undef, undef, $dataobj ) = @_;

                foreach my $creator( @{ $dataobj->value( "creators" ) } )
                {
                        my $output = $plugin->output_dataobj( $dataobj, $creator );
                        return unless( defined $output );
                        print "$output\n";
                }
        } );
}

sub output_dataobj
{
        my( $plugin, $dataobj, $creator ) = @_;

        my @row;
        push @row, $plugin->escape_value( $dataobj->id );

        push @row, $plugin->escape_value( EPrints::Utils::make_name_string( $creator->{name} ) );

        push @row, $plugin->escape_value( $creator->{id} );

        my $orcid = "No ORCID";
        if( EPrints::Utils::is_set( $creator->{orcid} ) )
        {
                $orcid = $creator->{orcid};
        }
        push @row, $plugin->escape_value( $orcid );

        return join( ",", @row );
}

1;
