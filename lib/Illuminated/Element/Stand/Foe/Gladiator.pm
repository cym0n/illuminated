package Illuminated::Element::Stand::Foe::Gladiator;

use v5.10;
use Moo;
extends 'Illuminated::Element::Stand::Foe';

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

sub strategy
{
    my $self = shift;
    my $game = shift;
    if(! $self->has_status('parry'))
    {
        return ('parry', undef);
    }
    return $self->_standard_ia($game, { 'close' => 'attack',
                                        'near'  => 'pursuit',
                                        'above'  => 'pursuit',
                                        'far'   => 'pursuit',
                                        'below' => 'pursuit' });
}

1;

