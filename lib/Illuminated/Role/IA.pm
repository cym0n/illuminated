package Illuminated::Role::IA;

use strict;
use v5.10;
use Moo::Role;

requires 'strategy';

sub ia
{
    my $self = shift;
    my $game = shift;
    my $call = $self->type;
    my ($command, $target) = $self->strategy($game);
    $game->execute_foe($self, $command, $target);
}

sub _standard_ia
{
    my $self = shift;
    my $game = shift;
    my $c = shift;
    my $priority = shift || ['close', 'near', 'far', 'below', 'above'];
    my $command = undef;
    my $target = undef;
    foreach my $distance (@{$priority})
    {
        my @pls = $game->at_distance($self, $distance);
        #Avoid trying to get close to an enemy with another foe close to it
        @pls = grep {
            ! ($distance eq 'near' && $c->{$distance} eq 'pursuit' && $game->at_distance($_, 'close'))
        } @pls;
        #Avoid attacking enemies on cover
        if($c->{$distance} eq 'attack')
        {
            @pls = grep {
                ! $_->cover
            } @pls;
        }
        if(@pls)
        {
            $command = $c->{$distance};
            if($self->focus && grep { $_->tag eq $self->focus->tag} @pls)
            {
                $target = $self->focus;
            }
            else
            {
                if(@pls == 1)
                {
                    $target = $pls[0];
                }
                else
                {
                    $game->log($self->name . " IA: Many targets available for command $command");
                    $target = $pls[$game->game_rand('IA choosing target', \@pls )];
                }
                $self->focus($target);
            }
            last;   
        }
    }
    #Cover enemies management
    my @pls = grep { $_->cover } @{$game->players};
    if(@pls)
    {
        my @pls_distance = ();
        foreach my $d ( qw(near far below above) ) #near has priority
        {
            @pls_distance = grep { $game->get_distance($self, $_) eq $d } @pls;
            if(@pls_distance)
            {
                $target = $pls_distance[$game->game_rand('IA choosing target on cover', \@pls )];
                $self->focus($target);
                $command = 'pursuit';
                last;
            }
            last if $command;
        }
    
    }
    if(! $command )
    {
        $command = 'wait';
    }
    return ($command, $target);
}

1;
