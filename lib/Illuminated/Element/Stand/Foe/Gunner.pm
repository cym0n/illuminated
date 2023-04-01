package Illuminated::Element::Stand::Foe::Gunner;

use v5.10;
use Moo;
extends 'Illuminated::Element::Stand::Foe';

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
                                        'near'  => 'away',
                                        'above'  => 'attack',
                                        'far'   => 'attack',
                                        'below' => 'pursuit' });
}

1;

