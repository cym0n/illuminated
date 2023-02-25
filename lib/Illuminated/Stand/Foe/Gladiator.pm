package Illuminated::Stand::Foe::Gladiator;

use v5.10;
use Moo;
extends 'Illuminated::Stand::Foe';

use Illuminated::Weapon::Caliban;
use Illuminated::Weapon::Aegis;

around BUILDARGS => sub {
    my ( $orig, $class, @args ) = @_;
 
    return $class->$orig({
        name => $args[0],
        type => 'gladiator',
        health => 2,
    });
};

sub BUILD {
    my ($self, $args) = @_;
    $self->add_weapon(Illuminated::Weapon::Caliban->new());
    $self->add_weapon(Illuminated::Weapon::Aegis->new());
};

1;

