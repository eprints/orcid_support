package EPrints::Plugin::Screen::EPMC::Orcid;

@ISA = ( 'EPrints::Plugin::Screen::EPMC' );

use strict;

sub new
{
    my( $class, %params ) = @_;

    my $self = $class->SUPER::new( %params );

    $self->{package_name} = 'orcid';

    return $self;
}

sub action_enable
{
    my( $self, $skip_reload ) = @_;

    $self->SUPER::action_enable( $skip_reload );
    my $repo = $self->{repository};

    my $filename = $repo->config( "config_path" )."/workflows/user/default.xml";

    # remove current version
    EPrints::XML::remove_package_from_xml( $filename, $self->{package_name} );
    # install new version
    my $insert = EPrints::XML::parse_xml( $repo->config( "lib_path" )."/workflows/user/orcid.xml" );
    EPrints::XML::add_to_xml( $filename, $insert->documentElement(), $self->{package_name} );
    
    $self->reload_config if !$skip_reload;
}
    
sub action_disable
{
	my( $self, $skip_reload ) = @_;
    
    $self->SUPER::action_disable( $skip_reload );
    my $repo = $self->{repository};

    my $filename = $repo->config( "config_path" )."/workflows/user/default.xml";
    EPrints::XML::remove_package_from_xml( $filename, $self->{package_name} );

    $self->reload_config if !$skip_reload;
}

1;
