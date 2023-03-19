package Illuminated::Role::StatusHolder;

use strict;
use v5.10;
use Moo::Role;

has status => (
    is => 'rw',
    default => sub { [] }
);
has status_counter => (
    is => 'ro',
    default => sub { {} }
);

sub has_status
{
    my $self = shift;
    my $s = shift;
    return grep { $_ =~ /^$s/ } @{$self->status}
}

sub activate_status
{
    my $self = shift;
    my $s = shift;
    my $counter = shift;
    if(! $self->has_status($s))
    {
        push @{$self->status}, $s;
    }
    if($counter)
    {
        if(defined $self->status_counter->{$s})
        {
            $self->status_counter->{$s} = $self->status_counter->{$s} + $counter;
        }
        else
        {
            $self->status_counter->{$s} = $counter;
        }
    }
}
sub deactivate_status
{
    my $self = shift;
    my $s = shift;
    @{$self->status} = grep { $_ ne $s} @{$self->status};
}
sub counters_clock
{
    my $self = shift;
    my $game = shift;
    foreach my $s (keys %{$self->status_counter})
    {
        if($self->status_counter->{$s} > 0)
        {
            $self->status_counter->{$s} = $self->status_counter->{$s} - 1;
            if($self->status_counter->{$s} == 0)
            {
                $game->log($self->name . ": status $s expired!");
                $self->deactivate_status($s);
            }
        }
    }
}

1;
