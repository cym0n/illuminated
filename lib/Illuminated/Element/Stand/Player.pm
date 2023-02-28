package Illuminated::Element::Stand::Player;

use v5.10;
use Moo;
extends 'Illuminated::Element::Stand';

has tag => (
    is => 'lazy'
);
sub _build_tag
{
    my $self = shift;
    return 'P-' . lc($self->name);
}
has game_type => (
    is => 'lazy'
);
sub _build_game_type
{
    my $self = shift;
    return 'player'
}
has power => (
    is => 'ro',
);
has speed => (
    is => 'ro'
);
has mind => (
    is => 'ro',
);

1;

