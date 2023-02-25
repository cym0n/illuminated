package Illuminated::Stand::Foe::Thug;

use v5.10;
use Moo;
extends 'Illuminated::Stand::Foe';

use Illuminated::Weapon::Balthazar;

around BUILDARGS => sub {
    my ( $orig, $class, @args ) = @_;
 
    return $class->$orig({
        name => $args[0],
        type => 'thug',
        health => 2,
    });
};

sub BUILD {
    my ($self, $args) = @_;
    $self->add_weapon(Illuminated::Weapon::Balthazar->new());
};

1;


