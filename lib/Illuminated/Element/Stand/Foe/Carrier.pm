package Illuminated::Element::Stand::Foe::Carrier;

use v5.10;
use Moo;
extends 'Illuminated::Element::Stand::Foe';

use Illuminated::Weapon::Balthazar;
use Illuminated::Weapon::Gospel;

around BUILDARGS => sub {
    my ( $orig, $class, @args ) = @_;
 
    return $class->$orig({
        name => $args[0],
        type => 'carrier',
        health => 2,
    });
};

sub BUILD {
    my ($self, $args) = @_;
    $self->add_weapon(Illuminated::Weapon::Balthazar->new());
    $self->add_weapon(Illuminated::Weapon::Gospel->new());
};

sub strategy
{
    my $self = shift;
    my $game = shift;
    if($game->unaware_foe() && ! $self->has_status('jammed'))
    {
        my $throw = $game->dice(1, 1);
        return ('warn', undef) if($throw < 3);
    }
    return $self->_standard_ia($game, { 'close' => 'away',
                                        'near'  => 'attack',
                                        'far'   => 'pursuit',
                                        'above'   => 'attack',
                                        'below' => 'pursuit' },
                                ['above', 'below', 'close', 'near', 'far']
    ); 
}

1;
