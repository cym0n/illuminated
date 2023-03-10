package Illuminated::Element::Stand;

use v5.10;
use Moo;
extends 'Illuminated::Element';

has energy => (
    is => 'rw'
);
has weapons => (
    is => 'ro',
    default => sub { [] }
);
has devices => (
    is => 'ro',
    default => sub { [] }
);
has status => (
    is => 'rw',
    default => sub { [] }
);
has status_counter => (
    is => 'ro',
    default => sub { {} }
);

sub add_weapon
{
    my $self = shift;
    my $weapon = shift;
    push @{$self->weapons}, $weapon;
}

sub add_device
{
    my $self = shift;
    my $device = shift;
    push @{$self->devices}, $device;
}

sub get_weapons_by_range
{
    my $self = shift;
    my $range = shift;
    my @out = ();
    foreach my $w (@{$self->weapons})
    {
        push @out, $w if $w->good_for_range($range);
    }    
    return @out;
}
sub get_weapon
{
    my $self = shift;
    my $name = shift;
    foreach my $w (@{$self->weapons})
    {
        return $w if $w->name eq $name;
    }
    return undef
}
sub get_device
{
    my $self = shift;
    my $name = shift;
    return undef if ! $name;
    foreach my $d (@{$self->devices})
    {
        return $d if $d->name eq $name;
    }
    return undef
}


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

sub use_energy
{
    my $self = shift;
    my $energy = shift;
    $self->energy($self->energy - $energy);
    if($self->energy < 0)
    {
        $self->energy(0);
    }
}

sub calculate_effects
{
    my $self = shift;
    my $game = shift;
    my $event = shift;
    my $data = shift;
    
    #$game->log("Stand " . $self->name . " processing event: $event");

    if($event eq 'before attack')
    {
        if($data->{subject_2}->tag eq $self->tag && $data->{weapon}->type eq 'sword' && $self->has_status('parry'))
        {
            $game->log($self->name . " null damage from " . $data->{subject_1}->name . " and lose parry");
            $self->deactivate_status('parry');
            $data->{damage} = 0;
        }
    }
    elsif($event eq 'dice disengage')
    {
        if($data->{subject_2}->tag eq $self->tag && $self->has_status('grab'))
        {
            $game->log($data->{subject_1}->name . " disengaging, but " . $self->name . " has grab");
            push @{$data->{dice_mods}}, '1max -1';
        }
    }
}


1;




