#
# this should be an abstract class
#

package EPrints::Plugin::Screen::BulkAction;

use EPrints::Plugin::Screen;

@ISA = ( 'EPrints::Plugin::Screen' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	$self->{processor} = $params{processor};

	#$self->_load_list() if( defined $self->{session} );

	$self->{actions} = [qw/ back /];

	return $self;
}

sub about_to_render
{
	my( $self ) = @_;

	$self->_load_list();
}



# TODO: think of an appropriate default perm:
sub can_be_viewed
{
	my( $self ) = @_;

	return 1;
}

sub render_no_eprints
{
	my( $self ) = @_;

	my $chunk = $self->{session}->make_doc_fragment;
	
	my $form = $self->{session}->make_element( "form" );
	$chunk->appendChild( $form );

	$form->appendChild( $self->{session}->make_element( "input", type=>"hidden", name=>"screen", value=>"BulkAction" ));

        my $div = $self->{session}->make_element( "div" , align => "center" );

        $form->appendChild( $div );

	$div->appendChild( $self->{session}->render_action_buttons( 
                _order => [ "back" ],
                back => $self->{session}->phrase( "Plugin/Screen/BulkAction:button:back" ),
        ) );
	
	$self->{processor}->add_message( "error", $self->{session}->html_phrase( "Plugin/Screen/BulkAction:no_eprints" ) );

	return $chunk;
}



sub _load_list
{
	my( $self ) = @_;

	return if( defined $self->{processor}->{eprints} && scalar(@{$self->{processor}->{eprints}}) );

	my @eprints;
	my $user = $self->{session}->current_user;
	
	$self->{processor}->{eprints} = [];

	foreach my $epid ( @{$self->_get_list_ids()} )
	{
		my $eprint = EPrints::DataObj::EPrint->new( $self->{session}, $epid );
		next unless( defined $eprint );

		# generic eprint API:
		unless( $eprint->has_owner( $user ) )
		{
			next unless( $eprint->in_editorial_scope_of( $user ) );
		}
		
		# edshare-specific extension:
		#next unless( $eprint->can_be_edited( $user ) );
		push @eprints, $eprint;
	}
	
	$self->{processor}->{eprints} = \@eprints;
}

sub get_eprints
{
	my( $self ) = @_;

	$self->_load_list unless defined $self->{processor}->{eprints};

	return $self->{processor}->{eprints};
}

sub _get_list_ids
{
	my( $self ) = @_;

	if( !defined $self->{processor}->{eprintids} )
	{
		$self->{processor}->{eprintids} = [];

		my @epids = $self->{session}->param( 'bulkaction_eprintids' );
		@epids = split /,/, $self->{session}->param( 'eprintids' ) unless( scalar @epids );
		if( scalar @epids )
		{
			$self->{processor}->{eprintids} = \@epids;
		}
	}

	return $self->{processor}->{eprintids};
}

sub render
{
	my( $self ) = @_;
	
	$self->{processor}->add_message( "error", $self->{session}->make_text( $self->get_id."->render() should be sub-classed." ) );

	return $self->{session}->make_doc_fragment;
}

sub render_summary_list
{
	my( $self, $eprints ) = @_;

	my $chunk = $self->{session}->make_doc_fragment;

	my $div = $self->{session}->make_element( "div", class=>'ep_manageable_list ep_bulkaction_summary_list' );
	$chunk->appendChild( $div );

	foreach my $eprint (@$eprints)
	{
		$div->appendChild( $eprint->render_citation( 'manageable_no_controls' ) );
	}

	return $chunk;
}

sub render_links
{
	my( $self ) = @_;
	
	my $session = $self->{session};
	my $base_url = $session->get_repository->get_conf( 'base_url' );
	
	my $style = $session->make_element( 'style', type => 'text/css', media => 'screen' );
	$style->appendChild( $session->make_text( '@import url('.$base_url.'/style/resourcemanager.css);' ) );

	my $links = $session->make_doc_fragment;
	$links->appendChild( $style );

	return $links;
}

sub allow_back
{
	return 1;
}

sub action_back
{
	my( $self ) = @_;

	$self->{processor}->{redirect} = $self->{processor}->{url}.'?screen=ResourceManager';
}


1;
