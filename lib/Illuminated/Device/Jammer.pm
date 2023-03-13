package Illuminated::Device::Jammer;

use v5.10;
use Moo;
extends 'Illuminated::Device';

has name => (
    is => 'ro',
    default => 'jammer'
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
    if($game->aware_foe())
    {
        return $self->$orig($game, $subject, $arg);
    }
};

sub get_targets
{
    my $self = shift;
    my $game = shift;
    my $subject = shift;
    my $arg = shift;
    return grep { $_->aware } @{$game->foes}; #Can be only on players
}

sub action
{
    my $self = shift;
    my $game = shift;
    my $subject = shift;
    my $arg = shift;
    foreach my $f ($self->get_targets($game, $subject, $arg))
    {
        $f->activate_status('jammed', 3);
        $game->log($f->name . " communications are jammed");
    }
}

1;
