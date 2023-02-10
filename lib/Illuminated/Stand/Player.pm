package Illuminated::Stand::Player;

use v5.10;
use Moo;
extends 'Illuminated::Stand';

has tag => (
    is => 'lazy'
);
sub _build_tag
{
    my $self = shift;
    return 'P-' . lc($self->name);
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

