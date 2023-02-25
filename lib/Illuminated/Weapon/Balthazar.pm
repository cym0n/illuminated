package Illuminated::Weapon::Balthazar;

use v5.10;
use Moo;
extends 'Illuminated::Weapon';

around BUILDARGS => sub {
  my ( $orig, $class, @args ) = @_;
 
  return $class->$orig({
        name => 'balthazar',
        type => 'rifle',
        try_type => 'mind',
        range => [ 'near' ],
        damage => 1
    });
};

1;
