package Illuminated::Tile::GuardedSpace;

use v5.10;
use Moo;
extends 'Illuminated::Tile';


has interface_header => (
    is => 'rw',
    default => "Entering enemy patrol zone"
);

has interface_options => (
    is => 'rw',
    default => sub {  [ 
        ['(N)', "[N]o strategy"], 
        ['(S)', "[S]tealth passage (mind try)"], 
        ['(R)', "[R]ush in (power try)"] 
    ] }
);
has foes => (
    is => 'ro',
    default => sub { [ [ 'alpha',   'Illuminated::Element::Stand::Foe::Thug' ],
                       [ 'beta',    'Illuminated::Element::Stand::Foe::Thug' ],
                       [ 'gamma',   'Illuminated::Element::Stand::Foe::Thug' ],
                       [ 'epsilon', 'Illuminated::Element::Stand::Foe::Thug' ],
                       [ 'delta',   'Illuminated::Element::Stand::Foe::Thug' ],
                       [ 'ro',      'Illuminated::Element::Stand::Foe::Gunner' ],
                       [ 'iota',    'Illuminated::Element::Stand::Foe::Gunner' ],
                       [ 'csi',     'Illuminated::Element::Stand::Foe::Gladiator' ],
                       [ 'pi',      'Illuminated::Element::Stand::Foe::Gladiator' ],
                     ] }
);

sub interface_preconditions
{
    my $self = shift;
    my $game = shift;
    if($game->aware_foe)
    {
        @{$self->interface_options} = grep {$_->[0] ne '(S)'} @{$self->interface_options};
        $self->interface_header("Entering enemy patrol zone (enemies already aware)");
    }
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
            $fobj->setup($game, $player, undef, undef);
        }
        return 1;
    }
    elsif($choice eq 'S')
    {
        my $throw = $game->dice($player->mind);
        if($throw >= 5)
        {
            $game->log("PASSED UNDETECTED!");
        }
        elsif($throw >= 3)
        {
            $game->log("Same result of no strategy");
            $self->gate_run($game, $player, 'N');
        }
        else
        {
            say "All enemies aware!"; #TODO: A turn to the enemy
            foreach my $f ( @{$self->foes} )
            {
                my $fobj = $game->get_foe($f->[0]);
                $fobj->setup($game, $player, undef, 1);
            }
        }
        return 1;
    }
    elsif($choice eq 'R')
    {
        my $throw = $game->dice($player->power);
        if($throw >= 3)
        {
            if($throw >= 5)
            {
                $game->log("Enemy killed by surprise! Close to a second enemy. All enemies aware!");
                my $f = $game->get_foe(undef);
                $game->kill($f);
            }
            else
            {
                $game->log("Close to an enemy! All enemies aware!");
            }
            my @available = grep { $game->at_distance($_, "close") == 0 } @{$game->foes};
            my $f2 = $available[$game->game_rand('close enemy on rush approach', \@available)];
            $f2->setup($game, $player, 'close', 1);
            foreach my $f3 ( @{$self->foes} )
            {
                my $fobj = $game->get_foe($f3->[0]);
                if($fobj && $fobj->tag ne $f2->tag)
                {
                    $fobj->setup($game, $player, undef, 1);
                }
            }
        }
        else
        {
            $game->log("All enemies aware!");
            foreach my $f ( @{$self->foes} )
            {
                my $fobj = $game->get_foe($f->[0]);
                $fobj->setup($game, $player, undef, 1);
            }
        }
        return 1;
    }

}


1;


