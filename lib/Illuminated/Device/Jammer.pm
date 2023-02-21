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
    if($game->aware_foe())
    {
        return $self->$orig($game, $subject);
    }
};

sub action
{
    my $self = shift;
    my $game = shift;
    my $subject = shift;
    my $arg = shift;
    foreach my $f (@{$game->foes})
    {
        if($f->aware)
        {
            $f->activate_status('jammed', 3);
            $game->log($f->name . " communications are jammed");
        }
    }
}

1;
