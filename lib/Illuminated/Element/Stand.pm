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
has cover => (
    is => 'rw',
    default => 0
);

with 'Illuminated::Role::StatusHolder';


sub add_weapon
{
    my $self = shift;
    my $weapon = shift;
    push @{$self->weapons}, $weapon;
    return $weapon;
}

sub add_device
{
    my $self = shift;
    my $device = shift;
    push @{$self->devices}, $device;
    return $device;
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
    
    if($event =~ /^before (.*)$/)
    {
        if($data->{subject_1}->tag eq $self->tag && $1 ne 'cover' && $data->{subject_1}->cover)
        {
            $game->log($data->{subject_1}->name . " leaves cover!");
            $data->{subject_1}->no_cover();
        }
    }
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
    elsif($event eq 'after fly_closer')
    {   
        if($game->get_distance($data->{subject_1}, $data->{subject_2}) eq 'close' && $data->{subject_2}->cover)
        {
            $data->{subject_2}->no_cover;
            $data->{subject_2}->activate_status('no-cover', 3);
            $game->log($data->{subject_2}->name . " cover broken!");
        }
    }
}
around dump => sub 
{
    my $orig = shift;
    my $self = shift;
    my $game = shift;
    my $event = shift;
    my $data = shift;
    my $out = $self->$orig();
    $out->{energy} = $self->energy;
    $out->{cover} = $self->cover;
    $out->{status} = $self->status_dump;
    my @weapons = ();
    foreach my $w (@{$self->weapons})
    {
        push @weapons, $w->dump();
    }
    $out->{weapons} = \@weapons;
    my @devices = ();
    foreach my $d (@{$self->devices})
    {
        push @devices, ref($d);
    }
    $out->{devices} = \@devices;
    return $out;
};
    


1;




