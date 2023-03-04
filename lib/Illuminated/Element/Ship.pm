package Illuminated::Element::Ship;

use v5.10;
use Moo;
extends 'Illuminated::Element';

around BUILDARGS => sub {
    my ( $orig, $class, @args ) = @_;
 
    return $class->$orig({
        name => $args[0],
        type => 'ship',
        health => 4,
    });
};
