package Illuminated::Role::Interactive::Game;

use strict;
use v5.10;
use Moo::Role;
with 'Illuminated::Role::Interactive';

has '+interface_header' => (
    is => 'rw',
    default => "Combat zone"
);
has system_options => (
    is => 'rw',
    default => sub { [
        ['(QUIT)', "Exit game"],
        ['(INTERFACE)', "Interface"],
        ['(SAVE)', "save"],
        ['(DUMP)( (.*))', "Dump"]
    ] }
);
has '+interface_options' => (
    is => 'rw',
    default => sub {  [ 
        ['(S)( (.*))?', "[S]ituation"], 
        ['(A)( (.*))',  "[A]ttack enemy (mind try)"], 
        ['(C)( (.*))',  "[C]lose on enemy (speed try)"], 
        ['(F)( (.*))', "[F]ly away from enemies (speed try)"], 
    ] }
);
has interface_weapons => (
    is => 'rw',
    default => sub { {} }
);
has interface_devices => (
    is => 'rw',
    default => sub { {} }
);

sub interface_preconditions
{
    my $self = shift;
    my $game = shift;

    my @options = (  ['^(S)( (.*))?$', "[S]ituation"] );
    my @ranges;
    if($game->at_distance($game->active_player, 'close'))
    {
        $self->interface_header("Combat zone - close combat");
        push @options, ['^(D)$', "[D]isengage (power try)"]; 
        @ranges = qw( close );
    }
    else
    {
        $self->interface_header("Combat zone");
        push @options, ['^(C)( (.*))$',  "[C]lose on enemy (speed try)"];
        push @options, ['^(F)( (.*))?$', "[F]ly away from enemies (speed try)"];
        if($self->on_ground($game->active_player))
        {
            push @options, ['^(L)$', "[L]ift (power try)"];
            if($game->active_player->can_cover())
            {
                push @options, ['^(V)$', "Co[V]er (turns covering to now: " . $game->active_player->cover . ")"];
            }
        }
        else
        {
            foreach my $o ($game->at_distance($game->active_player, 'near'))
            {
                if($o->ground)
                {
                    push @options, ['^(L)( (.*))?$', "[L]and (speed try)"];
                    last;
                }
            }
        }
        @ranges = qw( far near above);
    }
    my %already = ();
    my $i = 1;
    my %weapons_mapping = ();
    my %devices_mapping = ();
    foreach my $d (@ranges)
    {
        if($game->at_distance($game->active_player, $d))
        {
            my @weaps = $game->active_player->get_weapons_by_range($d);
            foreach my $w (@weaps)
            {
                if(! exists $already{$w->name})
                {
                    push @options, ['^(A' . $i. ')( (.*))?$', "[A" . $i . "]ttack enemy with " . $w->name . " (" . $w->try_type . " try)"];
                    $weapons_mapping{'A' . $i} = $w->name;
                    $i++
                }
            }
        }
    }
    $i = 1;
    if($game->active_player_device_chance)
    {
        foreach my $d(@{$game->active_player->devices})
        {
            if($d->preconditions($game, $game->active_player))
            {
                push @options, ['^(P' . $i. ')( (.*))?$', "[P" . $i . "]ower: " . $d->name];
                $devices_mapping{'P' . $i} = $d->name;
                $i++;
            }
        }
    }
    $self->interface_options(\@options);
    $self->interface_weapons(\%weapons_mapping);
    $self->interface_devices(\%devices_mapping);
}

1;
