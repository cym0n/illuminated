package Illuminated::Device;

use v5.10;
use Moo;

has name => (
    is => 'ro',
    default => 'generic device'
);

has energy_usage => (
    is => 'ro',
    default => 0
);

sub preconditions
{
    my $self = shift;
    my $game = shift;
    my $subject = shift;
    my $args = shift;
    return 0 if $subject->energy < $self->energy_usage;
    return 1;
}

sub check_command
{
    my $self = shift;
    my $game = shift;
    my $subject = shift;
    my $arg = shift;
    return 1;
}

sub action
{
    my $self = shift;
    my $game = shift;
    my $subject = shift;
    my $arg = shift;
}

1;
