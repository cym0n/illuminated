package Illuminated::Weapon::Reiter;

use v5.10;
use Moo;
extends 'Illuminated::Weapon';

around BUILDARGS => sub {
  my ( $orig, $class, @args ) = @_;
 
  return $class->$orig({
    name => 'reiter',
    type => 'rifle',
    try_type => 'mind',
    range => [ 'far' ],
    damage => 1
  });
};

1;
