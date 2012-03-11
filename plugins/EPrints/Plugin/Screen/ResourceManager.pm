package EPrints::Plugin::Screen::ResourceManager;

@ISA = ( 'EPrints::Plugin::Screen' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new( %params );

        $self->{appears} = [
                {
                        place => "key_tools",
                        position => 101,
                }
        ];

	return $self;
}

sub can_be_viewed
{
        my( $self ) = @_;

        return $self->allow( "items" ) 
}

sub render
{
	my( $self ) = @_;
	my $session = $self->{session};

	my $frag = $session->make_doc_fragment;
	$frag->appendChild( $self->render_action_list_bar( 'item_tools' ) );
	
	my $id_prefix = "ed_resourcemanager";
	my $panels = $session->make_element( 'div', id=>$id_prefix.'_panels', class=>'ep_tab_panel' );
	my $labels = {};
	my $links = {};

	my $types = $session->get_repository->get_conf( 'resourcemanager_display_types' );
	my $current = $types->[0];

	my( $screen, $panel );
	foreach my $type ( @$types )
	{
		$screen = $session->plugin( 'Screen::ResourceManagerTab' );

		if( defined $screen )
		{
			$screen->{processor} = $self->{processor};
			$labels->{$type} = $screen->render_title( $type );
			$links->{$type} = '#'.$type;
			$panel = $session->make_element( 'div', class => ( $type eq $current ? '' : 'ep_no_js' ), id => $id_prefix.'_panel_'.$type );
			$panel->appendChild( $screen->render( $type ) );
			$panels->appendChild( $panel );
		} 
	}
	my $tab_block = $session->make_element( 'div', class => 'ep_only_js' );
	my $tab_set = $session->render_tabs( id_prefix => $id_prefix, current => $current, tabs => $types, labels => $labels, links => $links );
	$tab_block->appendChild( $tab_set );

	$frag->appendChild( $tab_block );
	$frag->appendChild( $panels );
	
	return $frag;
}

sub render_links
{
	my( $self ) = @_;

	my $session = $self->{session};
	my $base_url = $session->get_repository->get_conf( 'base_url' );
	
	my $js = $session->make_element( 'script', type => 'text/javascript', src => $base_url.'/javascript/resourcemanager.js' );
	my $style = $session->make_element( 'style', type => 'text/css', media => 'screen' );
	$style->appendChild( $session->make_text( '@import url('.$base_url.'/style/resourcemanager.css);' ) );

	my $links = $session->make_doc_fragment;
	$links->appendChild( $js );
	$links->appendChild( $style ); 

	return $links;
}

sub phrase
{
	my( $self, $id, %bits ) = @_;

	my $base = 'Plugin/Screen/ResourceManager';

	return $self->{session}->phrase( $base.':'.$id, %bits );
}

sub html_phrase
{
	my( $self, $id, %bits ) = @_;

	my $base = 'Plugin/Screen/ResourceManager';

	return $self->{session}->html_phrase( $base.':'.$id, %bits );
}
1;
