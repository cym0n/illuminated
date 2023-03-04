package Illuminated::Tile::ShipEncounter;

use v5.10;
use Moo;
extends 'Illuminated::Tile';


has interface_header => (
    is => 'rw',
    default => "Mysterious ship in the space"
);

has interface_options => (
    is => 'rw',
    default => sub {  [ 
        ['(G)', "[G]o to the ship"], 
    ] }
);
has foes => (
    is => 'ro',
    default => sub { [ [ 'alpha',   'Illuminated::Element::Stand::Foe::Thug' ],
                       [ 'beta',    'Illuminated::Element::Stand::Foe::Thug' ],
                       [ 'gamma',   'Illuminated::Element::Stand::Foe::Thug' ],
                       [ 'epsilon', 'Illuminated::Element::Stand::Foe::Thug' ],
                       [ 'delta',   'Illuminated::Element::Stand::Foe::Thug' ],
                       [ 'zeta',   'Illuminated::Element::Stand::Foe::Thug' ],
                       [ 'ro',      'Illuminated::Element::Stand::Foe::Gladiator' ],
                       [ 'iota',    'Illuminated::Element::Stand::Foe::Gladiator' ],
                       [ 'csi',     'Illuminated::Element::Stand::Foe::Gladiator' ],
                       [ 'eta',     'Illuminated::Element::Stand::Foe::Gladiator' ],
                       [ 'theta',     'Illuminated::Element::Stand::Foe::Gladiator' ],
                       [ 'kappa',      'Illuminated::Element::Stand::Foe::Gladiator' ],
                     ] }
);

has others => (
    is => 'ro',
    default => sub { [ [ 'joyful sacrifice', 'Illuminated::Element::Ship' ] ] }
);

sub gate_run
{
    my $self = shift;
    my $game = shift;
    my $player = shift;
    my $choice = shift;
    
    if($choice eq 'N')
    {
        foreach my $f ( @{$self->foes} )
        {
            my $fobj = $game->get_foe($f->[0]);
            $self->setup_foe($game, $player, $fobj, undef, undef);
        }
        return 1;
    }
}
