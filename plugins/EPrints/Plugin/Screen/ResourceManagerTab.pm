#####################################################################
#
# EPrints::Plugin::Screen::ResourceManagerTab
#
#####################################################################

=pod

=head1 NAME

B<EPrints::Plugin::Screen::ResourceManagerTab> - This is a tab for
the resource manager.

=head1 DESCRIPTION

This class represents a tab for the resource manager, it will render
a list of the type supplied to the render method or, if you supply
the name of a package which extends this class then it will render
the output of that class.

=cut

package EPrints::Plugin::Screen::ResourceManagerTab;
          
@ISA = ( 'EPrints::Plugin::Screen' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new( %params );

	return $self;
}

sub render_title
{
	my( $self, $type ) = @_;

	my $title;

	if( defined $type )
	{
		$title = $self->html_phrase( $type.'_title' );
	}
	else
	{
		$title = $self->html_phrase( 'title' );
	}

	return $title;
}

sub render
{
	my( $self, $type ) = @_;

	my $session = $self->{session};
	my $frag = $session->make_doc_fragment;

	my $filter = $session->plugin( "ResourceManagerFilter" );
	my $eprint_list = $self->_get_list( $type, $filter );

	my( $table, $tr, $td );
	$table = $session->make_element( "table", width=>"100%" );
	$frag->appendChild( $table );
	$tr = $session->make_element( "tr" );
	$table->appendChild( $tr );
	$td = $session->make_element( "td", valign=>"top" );
	$tr->appendChild( $td );

	my $filter_box = $session->make_element( "div", class => "ed_resourcemanager_filter_box" );
	$td->appendChild( $filter_box );
	my $filter_title = $session->make_element( "div", class=>"ed_resourcemanager_filter_box_title" );
	$filter_title->appendChild( $session->make_text( "Filters" ) );
	$filter_box->appendChild( $filter_title );
	$filter_box->appendChild( $filter->render_filter_control( $eprint_list ) );

	my( $bulk_action_form_frag, $bulk_action_form ) = $self->_render_bulk_action_form( $type );

	#my $content_container = $session->make_element( "div", class=>"ed_resourcemanager_content" );
	#$frag->appendChild( $content_container );
	
	$td = $session->make_element( "td", valign=>"top", align=>"left" );
	$tr->appendChild( $td );

	$td->appendChild( $bulk_action_form_frag );
	$td->appendChild( $self->_render_list( $type, undef, $bulk_action_form ) );

	my $filter_fields = $filter->get_filter_fields;
	my %current_filter_values;
	map {
		my $filter_field = $_;
		my $metafield = $session->get_repository->get_dataset( 'eprint' )->get_field( $filter_field );
		$current_filter_values{$filter_field} = $filter->get_current_filter_values( $filter_field ); 
	} @{$filter_fields};
	my $loader_image_url = $session->get_repository->get_conf( 'rel_path' ).'/images/ajax-loader.gif';
	my $load_item_list_url = $session->get_repository->get_conf( 'rel_path' ).'/cgi/users/resourcemanager/load_item_list';
	my $manageable_list_id = $type.'_manageable_list';
	my %params = ( 'type' => $type, 't' => time );
	map {
		$params{$_} = EPrints::Utils::url_escape( join( ",", @{$current_filter_values{$_}} ) );
	} keys %current_filter_values;
	my $params_json = join( ", ", map {
		"'$_': '".$params{$_}."'";
	} keys %params );

		$frag->appendChild( $session->make_javascript("
document.observe('dom:loaded', function() {
	\$('$manageable_list_id').update('<img src=\\'$loader_image_url\\'/>');
	new Ajax.Request('$load_item_list_url', {
		method: 'get',
		parameters: { $params_json },
		onSuccess: function(response) {
			var html = response.responseText;
			\$('$manageable_list_id').update(html);
			}
	});
} );
	") );

	return $frag;
}

sub _render_bulk_action_form
{
	my( $self, $type ) = @_;

	my $session = $self->{session};

	my $frag = $session->make_doc_fragment;

	my $bulk_action_form = $session->make_element( 'form', method => 'get', action => $session->config( "https_cgiroot" )."/users/home", class => 'ep_bulkaction_form' );
	$bulk_action_form->appendChild( $self->_render_bulk_action_control( $type ) );
	
	$frag->appendChild( $bulk_action_form );	


	return( $frag, $bulk_action_form );
}

sub _render_list
{
	my( $self, $type, $eprints, $bulk_action_form ) = @_;

	my $session = $self->{session};

	my $frag;
	if( defined $bulk_action_form )
	{
		$frag = $bulk_action_form;
	}
	else
	{
		$frag = $session->make_doc_fragment;
	}

	my $list = $session->make_element( 'div', id => $type.'_manageable_list', class => 'ep_manageable_list' );
	$frag->appendChild( $list );
	
	if( defined $eprints )
	{	
		my %info;
		$info{dom} = $list;
		my $cb = sub {
			my( $session, $dataset, $eprint, $info ) = @_;
			my $url;
			if( $eprint->get_value( 'eprint_status' ) eq 'archive' )
			{
				$url = $eprint->get_url;
			}
			else
			{
				$url = $session->get_repository->get_conf( 'rel_path' ).'/cgi/users/home?screen=EPrint::Summary&eprintid='.$eprint->get_id;
			}
                        my $container = $session->make_element( "div", id => "manageable_id_".$eprint->get_id, class => "ep_manageable" );
                        $container->appendChild( $eprint->render_citation( 'manageable', url => $url ) );
                        $info->{dom}->appendChild( $container );
		};
		$eprints->map( $cb, \%info );
	}

	return $frag;
}

sub _get_list
{
	my( $self, $type, $filter ) = @_;

	my $session = $self->{session};
	my $user = $session->current_user;
	my $ds = $session->get_repository->get_dataset( 'eprint' );
	my $search = new EPrints::Search(
		satisfy_all => 1,
		session => $session,
		dataset => $ds,
	);
	$search->add_field( $ds->get_field( 'userid' ), $user->get_id );
	$search->add_field( $ds->get_field( 'type' ), $type );

	if( defined $filter )
	{
		foreach my $field ( @{$session->get_repository->get_conf( 'resourcemanager_filter_fields' ) } )
		{
			my @current_tags = @{$filter->get_current_filter_values( $field )};
			if( scalar @current_tags )
			{
				$search->add_field( $ds->get_field( $field ), join( ' ', @current_tags ), "IN", "ALL" );
			}
		}
	}
	
	return $search->perform_search;
}

sub _render_list_filter
{

}

sub _list_items
{
	my( $self ) = @_;

	my $session = $self->{session};

#BulkAction::Remove
#BulkAction::Collection

	my @items;

	foreach( "Remove", "Collection" )
	{
		my $plugin = $session->plugin( "Screen::BulkAction::$_" );
		next unless( defined $plugin );
		push @items, $plugin;
	}
	
	return @items;
}

sub _render_bulk_action_control
{
	my( $self, $type ) = @_;

	my $session = $self->{session};


	# This below should work, but it's complaining that $self->{processor} isn't defined...
	my @bulk_action_list = $self->action_list( 'edshare_bulk_actions' );
	#my @bulk_action_list = $self->_list_items( 'edshare_bulk_actions' );

	my $frag = $session->make_doc_fragment;

	if ( scalar @bulk_action_list )
	{
		my $bulk_action_select = $session->make_element( 'select', name => 'screen', id => 'bulk_action_select_'.$type );
		my $bulk_action_option = $session->make_element( 'option' );
		$bulk_action_option->appendChild( $self->html_phrase( 'select_bulk_action' ) );
		$bulk_action_select->appendChild( $bulk_action_option );
		foreach my $bulk_screen ( @bulk_action_list )
		{
			my $screen_id = $bulk_screen->{screen_id};
			$screen_id =~ s/Screen::(.*)/$1/;
			$bulk_action_option = $session->make_element( 'option', value => $screen_id );
			$bulk_action_option->appendChild( $bulk_screen->{screen}->render_title );
			$bulk_action_select->appendChild( $bulk_action_option );
		}

		$frag->appendChild( $self->html_phrase( 'with_selected_resources' ) );
		$frag->appendChild( $bulk_action_select );
		$frag->appendChild( $session->make_javascript(<<INIT_CONTROL
document.observe('dom:loaded', function() {
	\$('bulk_action_select_$type').observe('change',
		window.executeBulkAction.bindAsEventListener({}, '$type'));
});
INIT_CONTROL
		) );
	}

	return $frag;
}
1;
