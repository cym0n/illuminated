package Illuminated::Element;

use v5.10;
use Moo;

has name => (
    is => 'ro'
);
has type => (
    is => 'ro'
);
has health => (
    is => 'rw'
);
has active => (
    is => 'rw',
    default => 1
);
has tag => (
    is => 'lazy'
);
sub _build_tag
{
    my $self = shift;
    return 'X-' . lc($self->name);
}
sub harm
{
    my $self = shift;
    my $damage = shift;
    $self->health($self->health - $damage);
    $self->health(0) if $self->health < 0;
}


1;
