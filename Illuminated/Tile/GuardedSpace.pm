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
    elsif($choice eq 'S')
    {
        my $throw = $game->dice($player->mind);
        if($throw >= 5)
        {
            say "PASSED UNDETECTED!";
        }
        elsif($throw >= 3)
        {
            say "Same result of no strategy";
            $self->gate_run($game, $player, 'N');
        }
        else
        {
            say "All enemies aware!"; #TODO: A turn to the enemy
            foreach my $f ( @{$self->foes} )
            {
                my $fobj = $game->get_foe($f->[0]);
                $self->setup_foe($game, $player, $fobj, undef, 1);
            }
        }
    }
    elsif($choice eq 'R')
    {
        my $throw = $game->dice($player->power);
        $throw = 3;
        if($throw >= 3)
        {
            if($throw >= 5)
            {
                say "Enemy killed by surprise! Close to a second enemy. All enemies aware!";
                my $f = $game->get_foe(undef);
                $game->kill_foe($f);
            }
            else
            {
                say "Close to an enemy! All enemies aware!";
            }
            my $f2 = $game->get_foe(undef);
            $self->setup_foe($game, $player, $f2, 'close', 1);
            foreach my $f3 ( @{$self->foes} )
            {
                my $fobj = $game->get_foe($f3->[0]);
                if($fobj && $fobj->tag ne $f2->tag)
                {
                    $self->setup_foe($game, $player, $fobj, undef, 1);
                }
            }
        }
        else
        {
            say "All enemies aware!";
            foreach my $f ( @{$self->foes} )
            {
                my $fobj = $game->get_foe($f->[0]);
                $self->setup_foe($game, $player, $fobj, undef, 1);
            }
        }
    }

}


1;


