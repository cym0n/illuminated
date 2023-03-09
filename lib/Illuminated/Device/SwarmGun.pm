package Illuminated::Device::SwarmGun;

use v5.10;
use Moo;
extends 'Illuminated::Device';

has name => (
    is => 'ro',
    default => 'swarmgun'
);

has energy_usage => (
    is => 'ro',
    default => 1
);

around preconditions => sub {
    my $orig = shift;
    my $self = shift;
    my $game = shift;
    my $subject = shift;
    my $arg = shift;
    my @targets = $game->at_distance($subject, 'near');
    return 0 if ! @targets;
    return $self->$orig($game, $subject, $arg);
};

sub action
{
    my $self = shift;
    my $game = shift;
    my $subject = shift;
    my $arg = shift;
    my @targets = $game->at_distance($subject, 'near');
    foreach my $t (@targets)
    {
        $game->log($t->name . " got hit by the swarmgun");
        $game->harm($subject, $t, 1); 
    }
}

1;
