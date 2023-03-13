package Illuminated::Tile::SpaceStationAssault;

use v5.10;
use Moo;
extends 'Illuminated::Tile';


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
    default => sub { [ [ 'alpha',   'Illuminated::Element::Stand::Foe::Thug' ], ] }
);

has others => (
    is => 'ro',
    default => sub { [ [ 'tortuga', 'Illuminated::Element::SpaceStation' ] ] }
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
        return 1;
    }
}
1;
