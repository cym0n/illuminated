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

sub get_cover
{
    my $self = shift;
    $self->cover($self->cover + 1);
}
sub no_cover
{
    my $self = shift;
    $self->cover(0);
}
sub can_cover
{
    my $self = shift;
    return ( $self->cover < $self->mind ) && (! $self->has_status('no-cover') )
}

1;

