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
    if($game->unaware_foe())
    {
        my $throw = $game->dice(1, 1);
        return ('warn', undef) if($throw < 3);
    }
    return $self->_standard_ia($game, { 'close' => 'away',
                                        'near'  => 'attack',
                                        'far'   => 'pursuit' });
}

sub gunner
{
    my $self = shift;
    my $game = shift;
    if($game->unaware_foe())
    {
        my $throw = $game->dice(1, 1);
        return ('warn', undef) if($throw < 3);
    }
    return $self->_standard_ia($game, { 'close' => 'away',
                                        'near'  => 'away',
                                        'far'   => 'attack' });
}

sub gladiator
{
    my $self = shift;
    my $game = shift;
    if(! $self->has_status('parry'))
    {
        return ('parry', undef);
    }
    return $self->_standard_ia($game, { 'close' => 'attack',
                                        'near'  => 'pursuit',
                                        'far'   => 'pursuit' });
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
        my @pls = $game->foe_distance($self, $distance);
        @pls = grep {
            $distance eq 'near' && $c->{$distance} eq 'pursuit' && $game->someone_close($_)
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
                $target = $pls[rand @pls];
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
