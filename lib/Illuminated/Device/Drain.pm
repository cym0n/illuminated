package Illuminated::Device::Drain;

use v5.10;
use Moo;
extends 'Illuminated::Device';

has name => (
    is => 'ro',
    default => 'drain'
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
    return 0 if($subject->has_status('overheat'));
    return $self->$orig($game, $subject, $arg);
};

sub get_targets
{
    my $self = shift;
    my $game = shift;
    my $subject = shift;
    my $arg = shift;
    my @targets = ();
    if($subject->game_type eq 'foe')
    {
        @targets = @{$game->players}
    }
    elsif($subject->game_type eq 'player')
    {
        @targets = @{$game->foes}
    }
    return @targets;
}

sub action
{
    my $self = shift;
    my $game = shift;
    my $subject = shift;
    my $arg = shift;
    my @targets = $self->get_targets($game, $subject, $arg);
    
    foreach my $p (@targets)
    {
        $game->log($subject->name . " drains energy from " . $p->name);
        $p->use_energy(1);
    }
    $subject->activate_status('overheat', 3);
}

1;
