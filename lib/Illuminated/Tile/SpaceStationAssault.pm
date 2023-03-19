package Illuminated::Tile::SpaceStationAssault;

use v5.10;
use Moo;
extends 'Illuminated::Tile';

use Illuminated::Element::Scenario;


has interface_header => (
    is => 'rw',
    default => "Pirate's space station!"
);

has interface_options => (
    is => 'rw',
    default => sub {  [ 
        ['(A)', "[A]pproach"], 
    ] }
);
has foes => (
    is => 'ro',
    default => sub { [ [ 'alpha',   'Illuminated::Element::Stand::Foe::Carrier' ], 
                       [ 'beta',   'Illuminated::Element::Stand::Foe::Carrier' ],
                       [ 'gamma',   'Illuminated::Element::Stand::Foe::Thug' ],
                       [ 'delta',   'Illuminated::Element::Stand::Foe::Thug' ],
    ] }
);

has others => (
    is => 'ro',
    default => sub { [ [ 'tortuga', 'Illuminated::Element::Scenario::SpaceStation' ] ] }
);
has end_turn_action_points => (
    is => 'ro',
    default => 2
);

sub gate_run
{
    my $self = shift;
    my $game = shift;
    my $player = shift;
    my $choice = shift;
    
    if($choice eq 'A')
    {
        foreach my $f ( @{$self->foes} )
        {
            my $fobj = $game->get_foe($f->[0]);
            $fobj->setup($game, $player, undef, 1);
        }
        foreach my $o ( @{$self->others} )
        {
            my $obj = $game->get_other($o->[0]);
            $obj->setup($game);
        }
        my $airlock = $game->add_other(Illuminated::Element::Scenario->new({
            name => 'airlock',
            health => 20,
            type => 'space station component',
        }));
        my $space_station =  $game->get_other('tortuga');
        $game->set_far_from_all($airlock);
        $game->set_ground($airlock, $space_station);
        $airlock->activate_status('roof');
        
        return 1;
    }
}
1;
