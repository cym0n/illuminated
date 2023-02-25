package Illuminated::Weapon::Caliban;

use v5.10;
use Moo;
extends 'Illuminated::Weapon';

around BUILDARGS => sub {
  my ( $orig, $class, @args ) = @_;
 
  return $class->$orig({
      name => 'caliban',
      type => 'sword',
      try_type => 'power',
      range => [ 'close' ],
      damage => 2
  });
};

1;
