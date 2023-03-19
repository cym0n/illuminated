package Illuminated::Element::Scenario;

use v5.10;
use Moo;
extends 'Illuminated::Element';

with 'Illuminated::Role::StatusHolder';

sub description
{
    my $self = shift;
    return $self->name . " (" . $self->type . ")";
}

sub calculate_effects
{
    my $self = shift;
    my $game = shift;
    my $event = shift;
    my $data = shift;
    
    if($event eq 'before attack')
    {
        if($data->{subject_2}->tag eq $self->tag && $game->get_distance($data->{subject_1}, $data->{subject_2}) eq 'above' && $self->has_status("roof") )
        {
            $game->log($self->name . " can't be damaged from above");
            $data->{damage} = 0;
        }
    }
    return;
}

1;

