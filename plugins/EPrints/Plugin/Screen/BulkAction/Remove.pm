package EPrints::Plugin::Screen::BulkAction::Remove;

@ISA = ( 'EPrints::Plugin::Screen::BulkAction' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	$self->{appears} = [
		{
			place => "edshare_bulk_actions",
			position => 200,
		}	
	];

	$self->{actions} = [qw/ remove cancel /];
	
	return $self;
}

#sub properties_from_OLD
#{
#        my( $self ) = @_;
#
#        $self->_load_list;
#
#        $self->SUPER::properties_from;
#}


sub render
{
	my( $self ) = @_;

	my $session = $self->{session};
	my $user = $self->{session}->current_user;
	my $page = $self->{session}->make_doc_fragment();

	my $eprints = $self->get_eprints;

	unless( defined @$eprints )
	{
		return $self->render_no_eprints();
	}

	my $blurb = $session->make_element( 'p' );
	$blurb->appendChild( $self->html_phrase( 'blurb' ) );
	$page->appendChild( $blurb );

	$page->appendChild( $self->render_summary_list( $eprints ) );

	my $form = $session->render_form( "post" );
	$page->appendChild( $form );
	
	my $ids_string = "";
	my $is_first = 1;
	foreach(@$eprints)
	{	
		$ids_string .= $is_first ? $_->get_id : ",".$_->get_id;
		$is_first = 0;
	}

	$form->appendChild( $session->make_element( "input" , type=>"hidden", name=>"eprintids", value=> "$ids_string" ) );
	$form->appendChild( $session->make_element( "input", type=>"hidden", name=>"screen", value => "BulkAction::Remove" ) );

        my $div = $self->{session}->make_element(
                "div" ,
                class => "ep_search_buttons" );

	$form->appendChild( $div );

        $div->appendChild( $self->{session}->render_action_buttons(
                _order => [ "remove", "cancel" ],
                remove => $self->phrase( "button:remove" ),
                cancel => $self->phrase( "button:cancel" ) )
        );

	return $page;
}

sub allow_remove
{
	my( $self ) = @_;

	return $self->can_be_viewed();
}

sub allow_cancel
{
	my( $self ) = @_;

	return $self->can_be_viewed();
}

sub action_remove
{
	my( $self ) = @_;

	my $eprints = $self->get_eprints();

	my @problems;

	foreach my $eprint ( @$eprints )
	{
		unless( $eprint->remove )
		{
	                my $db_error = $self->{session}->get_database->error;
        	        $self->{session}->get_repository->log( "DB error removing EPrint ".$self->{processor}->{eprint}->get_value( "eprintid" ).": $db_error" );
            		push @problems, $eprint->get_id;
		}
	}

	if( scalar( @problems ) )
	{
		# TODO display error
	}

	$self->{processor}->{screenid} = "ResourceManager";	
}

sub action_cancel
{
	my( $self ) = @_;

	$self->{processor}->{screenid} = "ResourceManager";
}




1;
