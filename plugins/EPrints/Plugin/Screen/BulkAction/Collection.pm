package EPrints::Plugin::Screen::BulkAction::Collection;

@ISA = ( 'EPrints::Plugin::Screen::BulkAction' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new( %params );

	$self->{appears} = [
		{
			place => "edshare_bulk_actions",
			position => 100,
		}
	];

	$self->{actions} = [ qw/ create update / ];

	return $self;
}

sub allow_create
{
	return 1;
}

sub action_create
{
	my( $self ) = @_;
	
	my $session = $self->{session};
	
	my $ds = $session->get_repository->get_dataset( 'inbox' );
	my $user = $session->current_user;

	$self->{processor}->{eprint} = $ds->create_object( $self->{session}, {
		userid => $user->get_id,
		type => 'collection'
	} );
	
	if( !defined $self->{processor}->{eprint} )
	{
		my $db_error = $session->get_database->error;
		$session->get_repository->log( "Database Error: $db_error" );
		$self->{processor}->add_message(
			"error",
			$self->html_phrase( "db_error" ) );
		return;
	}	

	foreach my $epid ( split( ',', $session->param( 'eprintids' ) ) )
	{
		$self->{processor}->{eprint}->add_to_collection( $epid );
	}

	$self->{processor}->{eprint}->commit;

	$self->{processor}->{eprintid} = $self->{processor}->{eprint}->get_id;
	$self->{processor}->{screenid} = "EPrint::Edit";
}

sub allow_update
{
	return 1;
}

sub action_update
{
	my( $self ) = @_;

	my $session = $self->{session};

	my $collection = new EPrints::DataObj::EPrint( $session, $session->param( 'eprintid' ) );
	if( defined $collection )
	{
		foreach my $epid ( split( ',', $session->param( 'eprintids' ) ) )
		{
			$collection->add_to_collection( $epid );
		}

		$collection->commit;

		$self->{processor}->{eprint} = $collection;
		$self->{processor}->{eprintid} = $collection->get_id;
		$self->{processor}->{screenid} = "EPrint::Edit";
	}
}

sub render
{
	my( $self ) = @_;

	my $session = $self->{session};
	my $user = $session->current_user;
	my $page = $session->make_doc_fragment;

	my $eprints = $self->get_eprints;

	unless( scalar @$eprints )
	{
		return $self->render_no_eprints;
	}

	my $blurb = $session->make_element( 'p' );
	$blurb->appendChild( $self->html_phrase( 'blurb' ) );
	$page->appendChild( $blurb );

	$page->appendChild( $self->render_summary_list( $eprints ) );

	my $new_form = $session->render_form;
	$page->appendChild( $new_form );

	my $ids_string = "";
	my $is_first = 1;
	foreach ( @$eprints )
	{
		$ids_string .= $is_first ? $_->get_id : ','.$_->get_id;
		$is_first = 0;
	}

	my $new_title = $session->make_element( 'h3' );
	$new_title->appendChild( $self->html_phrase( 'newcollection:title' ) );
	$new_form->appendChild( $new_title );

	my $new_description = $session->make_element( 'p' );
	$new_description->appendChild( $self->html_phrase( 'newcollection:description' ) );
	$new_form->appendChild( $new_description );

	$new_form->appendChild( $session->make_element( 'input', type => 'hidden', name => 'screen', value => 'BulkAction::Collection' ) );
	$new_form->appendChild( $session->make_element( 'input', type => 'hidden', name => 'eprintids', value => $ids_string ) );
	$new_form->appendChild( $session->render_action_buttons(
		create => $self->phrase( 'newcollection:create' ),
	) );

	my $existing_form = $session->render_form;
	$page->appendChild( $existing_form );
	
	my $existing_title = $session->make_element( 'h3' );
	$existing_title->appendChild( $self->html_phrase( 'existingcollection:title' ) );
	$existing_form->appendChild( $existing_title );

	my $existing_description = $session->make_element( 'p' );
	$existing_description->appendChild( $self->html_phrase( 'existingcollection:description' ) );
	$existing_form->appendChild( $existing_description );

	my $existing_collections = $session->make_element( 'select', name => 'eprintid' );
	$existing_form->appendChild( $existing_collections );

	my $collection_ds = $session->get_repository->get_dataset( 'eprint' );
	my $search = EPrints::Search->new(
		satisfy_all => 1,
		session => $session,
		dataset => $collection_ds
	);
	$search->add_field( $collection_ds->get_field( 'type' ), 'collection' );
	$search->add_field( $collection_ds->get_field( 'userid' ), $session->current_user->get_id );
	my $list = $search->perform_search;
	foreach my $collection ( $list->get_records )
	{
		my $option = $session->make_element( 'option', value => $collection->get_id );
		$option->appendChild( $collection->render_value( 'title' ) );
		$existing_collections->appendChild( $option );
	}	

	$existing_form->appendChild( $session->make_element( 'input', type => 'hidden', name => 'screen', value => 'BulkAction::Collection' ) );
	$existing_form->appendChild( $session->make_element( 'input', type => 'hidden', name => 'eprintids', value => $ids_string ) );
	$existing_form->appendChild( $session->render_action_buttons(
		update => $self->phrase( 'existingcollection:update' ),
	) );

	return $page;
}
1;
