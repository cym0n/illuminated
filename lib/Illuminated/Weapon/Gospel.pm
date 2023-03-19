package Illuminated::Weapon::Gospel;

use v5.10;
use Moo;
extends 'Illuminated::Weapon';

around BUILDARGS => sub {
  my ( $orig, $class, @args ) = @_;
 
  return $class->$orig({
        name => 'gospel',
        type => 'bomb',
        try_type => 'mind',
        range => [ 'above' ],
        damage => 2
    });
};

1;
