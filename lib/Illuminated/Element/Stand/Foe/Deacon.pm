package Illuminated::Element::Stand::Foe::Deacon;

use v5.10;
use Moo;
extends 'Illuminated::Element::Stand::Foe';

use Illuminated::Weapon::Caliban;
use Illuminated::Weapon::Aegis;
use Illuminated::Device::Drain;

around BUILDARGS => sub {
    my ( $orig, $class, @args ) = @_;
 
    return $class->$orig({
        name => $args[0],
        type => 'deacon',
        health => 6,
        energy => 3,
    });
};

sub BUILD {
    my ($self, $args) = @_;
    $self->add_weapon(Illuminated::Weapon::Caliban->new());
    $self->add_device(Illuminated::Device::Drain->new());
    $self->activate_status('grab');
};

sub strategy
{
    my $self = shift;
    my $game = shift;
    if($self->get_device('drain')->preconditions($game, $self))
    {
        return ('device drain', undef);
    }
    return $self->_standard_ia($game, { 'close' => 'attack',
                                        'near'  => 'pursuit',
                                        'far'   => 'pursuit', 
                                        'above' => 'pursuit'});
}
1;

