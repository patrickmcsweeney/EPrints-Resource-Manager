#############################################
# ResourceManager Settings File
#############################################

# resourcemanager_items_screen_enabled
#
# When set to 1 the items screen will still be displayed alongside the resourcemanager
# set this to 0 to disable the items screen and only have the resourcemanager.
$c->{resourcemanager_items_screen_enabled} = 0;

# resourcemanager_display_types
#
# This is the list of eprint types that you want to manage in the resource manager.
# If this list is empty or undefined then the plugin will fallback to the list of
# eprint types specified in archives/ARCHIVEID/cfg/namedsets/eprint

#$c->{resourcemanager_display_types} = [
#	'article',
#	'resource',
#	'collection'
#];

# resourcemanager_filter_fields
#
# These are the fields that you want to use with the resourcemanager filter.
# The fields must be multiple value text fields in order to be used. If they
# aren't then they will be ignored.
$c->{resourcemanager_filter_fields} = [
	'keywords'
];

# resourcemanager_item_list_render
#
# Whenever the item list for the resourcemanager is rendered this function
# is called. It will be called x times where x is the length of the
# resourcemanager_display_types list. It recieves 4 parameters and is expected
# to return 1 value.
#
# Parameters:
#   session - The session object associated with the current request.
#   type - The string indicating the type being rendered.
#   filter - The EPrints::Plugin::ResourceManagerFilter object that should be
#   applied to this list. Of course you could choose to ignore this. If this
#   comes in as undef then there is no filter that needs to be applied.
#
# Return:
#   This function is expected to return an Document Fragment object at the very
#   least. 
$c->{resourcemanager_item_list_render} = sub
{
	my( $session, $type, $filter ) = @_;

	my $user = $session->current_user;
	my $eprint_ds = $session->get_repository->get_dataset( 'eprint' );
	my $user_owned_eprints = $user->get_owned_eprints( $eprint_ds );
	my $search = new EPrints::Search(
		satisfy_all => 1,
		session => $session,
		dataset => $eprint_ds,
	);
	$search->add_field( $eprint_ds->get_field( 'type' ), $type );
	if( defined $filter )
	{
		foreach my $field ( @{$session->get_repository->get_conf( 'resourcemanager_filter_fields' )} )
		{
			my @current_tags = @{$filter->get_current_filter_values( $field )};
			if( scalar @current_tags )
			{
				$search->add_field( $eprint_ds->get_field( $field ), join( ' ', @current_tags ), "IN", "ALL" );
			}
		}
	}
	my $filtered_eprint_list = $search->perform_search;
	$filtered_eprint_list = $filtered_eprint_list->intersect( $user_owned_eprints, "title" );
	# sf2 - ordering by lastmod	
	$filtered_eprint_list = $filtered_eprint_list->reorder( "-lastmod" );

	my $item_list = $session->make_doc_fragment;

	if( !$filtered_eprint_list->count )
	{
		$item_list->appendChild( $session->html_phrase( 'cgi/resourcemanager:no_resources' ) );
	}
	else
	{
		my %info;
		$info{dom} = $item_list;

	
		$filtered_eprint_list->map( sub{
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
		}, \%info );
	}

	return $item_list;
};

if( $c->{resourcemanager_items_screen_enabled} == 0 )
{
	$c->{plugins}->{"Screen::Items"}->{appears}->{key_tools} = undef;
	$c->{plugin_alias_map}->{"Screen::Items"} = "Screen::ResourceManager";
	$c->{plugins}->{"Screen::ResourceManager"}->{appears}->{key_tools} = 100;
}

$c->{plugins}->{"Screen::ResourceManagerTab"}->{appears}->{resourcemanager_tabs} = undef;
$c->{plugins}->{"ResourceManagerFilter"}->{params}->{disable} = 0;
$c->{plugins}->{"Screen::BulkAction"}->{params}->{disable} = 0;
$c->{plugins}->{"Screen::BulkAction::Collection"}->{params}->{disable} = 0;
$c->{plugins}->{"Screen::BulkAction::Remove"}->{params}->{disable} = 0;
$c->{plugins}->{"Screen::ResourceManager"}->{params}->{disable} = 0;
$c->{plugins}->{"Screen::ResourceManagerTab"}->{params}->{disable} = 0;
