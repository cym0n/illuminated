package Illuminated::Stand;

use v5.10;
use Moo;

has name => (
    is => 'ro'
);
has type => (
    is => 'ro'
);
has health => (
    is => 'rw'
);
has active => (
    is => 'rw',
    default => 1
);
has tag => (
    is => 'lazy'
);
sub _build_tag
{
    my $self = shift;
    return 'X-' . lc($self->name);
}
has weapons => (
    is => 'ro',
    default => sub { [] }
);
has status => (
    is => 'rw',
    default => sub { [] }
);

sub add_weapon
{
    my $self = shift;
    my $weapon = shift;
    push @{$self->weapons}, $weapon;
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

sub calculate_effects
{
}

sub has_status
{
    my $self = shift;
    my $s = shift;
    return grep { $_ eq $s} @{$self->status}
}

sub activate_status
{
    my $self = shift;
    my $s = shift;
    if(! $self->has_status($s))
    {
        push @{$self->status}, $s;
    }
}
sub deactivate_status
{
    my $self = shift;
    my $s = shift;
    @{$self->status} = grep { $_ ne $s} @{$self->status};
}


1;



