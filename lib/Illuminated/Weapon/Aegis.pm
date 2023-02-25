package Illuminated::Weapon::Aegis;

use v5.10;
use Moo;
extends 'Illuminated::Weapon';

around BUILDARGS => sub {
  my ( $orig, $class, @args ) = @_;
 
  return $class->$orig({
    name => 'aegis',
    type => 'shield',
    try_type => 'power',
    range => [ ],
    damage => 0
  });
};

1;
