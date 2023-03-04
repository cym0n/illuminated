package Illuminated::Element::Ship;

use v5.10;
use Moo;
extends 'Illuminated::Element';

around BUILDARGS => sub {
    my ( $orig, $class, @args ) = @_;
 
    return $class->$orig({
        name => $args[0],
        type => 'ship',
        health => 4,
    });
};

sub setup
{
    my $self = shift;
    my $game = shift;
    $game->set_far_from_all($self);
}

1;
