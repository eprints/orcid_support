package EPrints::Plugin::Export::Report::CSV::EditorsOrcid;

use EPrints::Plugin::Export::Report::CSV;
our @ISA = ( "EPrints::Plugin::Export::Report::CSV" );

use strict;

sub new
{
        my( $class, %params ) = @_;

        my $self = $class->SUPER::new( %params );

        $self->{name} = "CSV";
        $self->{accept} = [ 'report/orcid-editors', ];
        $self->{advertise} = 1;
        return $self;
}

sub output_list
{
        my( $plugin, %opts ) = @_;

        my @titles = ("EPrintID", "Editors Name", "Editors ID", "ORCID");

        print join( ",", @titles );
        print "\n";

        $opts{list}->map( sub {
                my( undef, undef, $dataobj ) = @_;

                foreach my $editor( @{ $dataobj->value( "editors" ) } )
                {
                        my $output = $plugin->output_dataobj( $dataobj, $editor );
                        return unless( defined $output );
                        print "$output\n";
                }
        } );
}

sub output_dataobj
{
        my( $plugin, $dataobj, $editor ) = @_;

        my @row;
        push @row, $plugin->escape_value( $dataobj->id );

        push @row, $plugin->escape_value( EPrints::Utils::make_name_string( $editor->{name} ) );

        push @row, $plugin->escape_value( $editor->{id} );

        my $orcid = "No ORCID";
        if( EPrints::Utils::is_set( $editor->{orcid} ) )
        {
                $orcid = $editor->{orcid};
        }
        push @row, $plugin->escape_value( $orcid );

        return join( ",", @row );
}

1;
