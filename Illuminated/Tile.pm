package Illuminated::Tile;

use v5.10;
use Moo;

has name => (
    is => 'ro'
);
has interface_options => (
    is => 'ro',
    default => sub { [] }
);
has running => (
    is => 'rw',
    default => 0,
);
has foes => (
    is => 'ro',
    default => sub { [] }
);

sub gate_interface
{
    say "No interface provided for this tile"
}
sub gate_choice
{
    my $self = shift;
    my $answer = undef;
    my @options =  @{$self->interface_options};
    $self->gate_interface();
    $answer = <STDIN>;
    $answer = uc($answer);
    chomp $answer;
    if(grep { $answer =~ /^$_/ } @options)
    {
        return $answer;
    }
    else
    {
        say "Bad option";
        return undef;
    }
}
sub gate_run
{
    say "Nothing to do";
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


sub setup_foe
{
    my $self = shift;
    my $game = shift;
    my $p = shift;
    my $f = shift;
    my $distance = shift;
    my $awareness = shift;

    $awareness = 1 if $f->aware;
    my $throw = $game->dice(1, 1);
    my $a;
    my $d;
    if($throw >= 5)
    {
        $a = defined $awareness ? $awareness : 0;
        $d = $distance ? $distance : 'far'; #Used only if enemy already aware
    }
    elsif($throw >= 3)
    {
        $a = defined $awareness ? $awareness : 1;
        $d = $distance ? $distance : 'far';
    }
    else
    {
        $a = defined $awareness ? $awareness : 1;
        $d = $distance ? $distance : 'near';
    }
    $f->aware($a);
    if($f->aware)
    {
        $game->set_foe_distance($p->name, $f->name, $d);
        $game->set_foe_far_from_all($f);
        my $d_label = $d;
        $d_label .= $d eq 'far' ? " from " : " ";
        $d_label .= $p->name;
        say $f->name . " is aware and " . $d_label;
    }
    else
    {
        say $f->name . " is unaware";
    }
}



1;
