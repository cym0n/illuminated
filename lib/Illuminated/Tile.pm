package Illuminated::Tile;

use v5.10;
use Moo;

with 'Illuminated::Role::Interactive';

has name => (
    is => 'ro'
);

has entered => (
    is => 'rw',
    default => 0,
);
has foes => (
    is => 'ro',
    default => sub { [] }
);
has others => (
    is => 'ro',
    default => sub { [] }
);
has end_turn_action_points => (
    is => 'ro',
    default => 1
);

sub gate_run
{
    say "Nothing to do";
}

sub init
{
    my $self = shift;
    my $game = shift;
    $game->log(ref($self));
    $self->init_foes($game);
    $self->init_others($game);
}


sub init_foes
{
    my $self = shift;
    my $game = shift;
    foreach my $f (@{$self->foes})
    {
        $game->add_foe($f->[0], $f->[1])
    }
}
sub init_others
{
    my $self = shift;
    my $game = shift;
    foreach my $o (@{$self->others})
    {
        $game->add_other($o->[0], $o->[1])
    }
}
sub execute_turn
{
    my $self = shift
}



1;
