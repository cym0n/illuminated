package Illuminated::Weapon;

use v5.10;
use Moo;

has name => (
    is => 'ro'
);
has type => (
    is => 'ro',
);
has try_type => (
    is => 'ro',
);
has range => (
    is => 'ro',
);
has damage => (
    is => 'ro'
);

sub good_for_range
{
    my $self = shift;
    my $range = shift;
    if(grep { $_ eq $range } @{$self->range})
    {
        return 1;
    }
    else
    {
        return 0;
    }
}

sub calculate_effects
{
}

1;
