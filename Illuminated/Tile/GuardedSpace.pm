package Illuminated::Tile::GuardedSpace;

use v5.10;
use Moo;
extends 'Illuminated::Tile';

has interface_options => (
    is => 'rw',
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
    my $self = shift;
    my $game = shift;
    if($game->aware_foe)
    {
        @{$self->interface_options} = grep {$_ ne 'S'} @{$self->interface_options};
    }
    say "Entering enemy patrol zone";
    say "[N]o strategy" if grep {$_ eq 'N'} @{$self->interface_options};
    say "[S]tealth passage (mind try)" if grep {$_ eq 'S'} @{$self->interface_options};
    say "[R]ush in (power try)" if grep {$_ eq 'R'} @{$self->interface_options};
    print "Choose: ";
}

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
        return 1;
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
        return 1;
    }

}


1;


