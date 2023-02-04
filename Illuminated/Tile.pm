package Illuminated::Tile;

use v5.10;
use Moo;

has name => (
    is => 'ro'
);
has running => (
    is => 'rw',
    default => 0,
);

1;
