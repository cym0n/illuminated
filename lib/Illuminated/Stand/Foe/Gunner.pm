package Illuminated::Stand::Foe::Gunner;

use v5.10;
use Moo;
extends 'Illuminated::Stand::Foe';

use Illuminated::Weapon::Reiter;

around BUILDARGS => sub {
    my ( $orig, $class, @args ) = @_;
 
    return $class->$orig({
        name => $args[0],
        type => 'gunner',
        health => 2,
    });
};

sub BUILD {
    my ($self, $args) = @_;
    $self->add_weapon(Illuminated::Weapon::Reiter->new());
};

1;

