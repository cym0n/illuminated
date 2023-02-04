package Illuminated::Tile::GuardedSpace;

use v5.10;
use Moo;
extends 'Illuminated::Tile';

has interface_options => (
    is => 'ro',
    default => sub { ['N', 'S', 'R'] }
);
has foes => (
    is => 'ro',
    default => sub { [ [ 'alpha',    'thug'   ],
                       [ 'beta',     'thug'   ],
                       [ 'gamma',    'thug'   ],
                       [ 'epsilon',  'thug'   ],
                       [ 'delta',    'thug'   ],
                       [ 'ro',       'gunner' ],
                       [ 'iota',     'gunner' ],
                     ] }
);

sub gate_interface
{
    say "Entering enemy patrol zone";
    say "[N]o strategy";
    say "[S]tealth passage (mind try)";
    say "[R]ush in (power try)";
    print "Choose: ";
}

sub gate_run
{
    my $self = shift;
    my $game = shift;
    my $player = shift;
    my $choice = shift;
    
    $self->init_foes($game);
    if($choice eq 'N')
    {
        foreach my $f ( @{$self->foes} )
        {
            my $fobj = $game->get_foe($f->[0]);
            $self->setup_foe($game, $player, $fobj, undef, undef);
        }
    }
}


1;


