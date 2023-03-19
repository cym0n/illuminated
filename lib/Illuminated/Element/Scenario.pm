package Illuminated::Element::Scenario;

use v5.10;
use Moo;
extends 'Illuminated::Element';

with 'Illuminated::Role::StatusHolder';

sub calculate_effects
{
    my $self = shift;
    return;
}

1;

