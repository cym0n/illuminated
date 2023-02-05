package Illuminated::Stand::Foe;

use v5.10;
use Moo;
extends 'Illuminated::Stand';

has tag => (
    is => 'lazy'
);
sub _build_tag
{
    my $self = shift;
    return 'F-' . lc($self->name);
}
has aware => (
    is => 'rw',
    default => 0,
);
has focus => (
    is => 'rw',
    default => undef,
);
has action_points => (
    is => 'rw',
    default => 0,
);

with 'Illuminated::Role::IA';

sub aware_text
{
    my $self = shift;
    if($self->aware)
    {
        return 'aware';
    }
    else
    {
        return 'unaware';
    }
}

1;
