package Illuminated::Role::IA;

use strict;
use v5.10;
use Moo::Role;

sub ia
{
    my $self = shift;
    my $game = shift;
    my $call = $self->type;
    my ($command, $target) = $self->$call($game);
    $game->execute_foe($self, $command, $target);
}

sub thug
{
    my $self = shift;
    my $game = shift;
    return $self->_standard_ia($game, { 'close' => 'away',
                                        'near'  => 'attack',
                                        'far'   => 'pursuit' });
}

sub gunner
{
    my $self = shift;
    my $game = shift;
    return $self->_standard_ia($game, { 'close' => 'away',
                                        'near'  => 'away',
                                        'far'   => 'attack' });
}

sub _standard_ia
{
    my $self = shift;
    my $game = shift;
    my $c = shift;
    my $command = undef;
    my $target = undef;
    if($game->unaware_foe())
    {
        my $throw = $game->dice(1, 1);
        $command = 'warn' if($throw < 3);
    }
    if(! $command)
    {
        foreach my $distance (qw(close near far))
        {
            my @pls = $game->foe_distance($self, $distance);
            if(@pls)
            {
                $command = $c->{$distance};
                if($self->focus && grep { $_->tag eq $self->focus->tag} @pls)
                {
                    $target = $self->focus;
                }
                else
                {
                    $target = $pls[rand @pls];
                    $self->focus($target);
                }
                last;   
            }
        }
    }
    if(! $command )
    {
        $command = 'wait';
    }
    return ($command, $target);
}

1;
