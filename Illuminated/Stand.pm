package Illuminated::Stand;

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
    is => 'rw'
);
has tag => (
    is => 'lazy'
);
sub _build_tag
{
    my $self = shift;
    return 'X-' . lc($self->name);
}

1;



