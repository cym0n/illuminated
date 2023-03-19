package Illuminated::Element::Scenario::SpaceStation;

use v5.10;
use Moo;
extends 'Illuminated::Element::Scenario';

has game_type => (
    is => 'lazy'
);
sub _build_game_type
{
    my $self = shift;
    return 'ship'
}

around BUILDARGS => sub {
    my ( $orig, $class, @args ) = @_;
 
    return $class->$orig({
        name => $args[0],
        type => 'space station',
        ground => 1,
        health => undef,
    });
};

sub setup
{
    my $self = shift;
    my $game = shift;
    $game->set_far_from_all($self);
}

sub suitable
{
    my $self = shift;
    my $game = shift;
    my $command = shift;
    return 1 if ! $command;
    if($command eq 'fly_closer')
    {
        if($game->get_distance($game->active_player, $self) eq 'near')
        {
            return 0; #You can't get close to ship
        }
    }
    elsif($command eq 'fly_away')
    {
        if($game->get_distance($game->active_player, $self) ne 'near') { return 0 }
    }
    return 1;
}

1;
