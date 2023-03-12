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
    my $command = undef;
    my $target = undef;
    foreach my $distance (qw(close near far))
    {
        my @pls = $game->at_distance($self, $distance);
        my $debug_pls = "";
        if(@pls)
        {
            for(@pls) { $debug_pls .= " " . $_->name; };
        }
        @pls = grep {
            ! ($distance eq 'near' && $c->{$distance} eq 'pursuit' && $game->at_distance($_, 'close'))
        } @pls;
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
    if(! $command )
    {
        $command = 'wait';
    }
    return ($command, $target);
}

1;
