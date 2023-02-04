package Illuminated::Game;

use v5.10;
use Moo;
use Illuminated::Stand::Player;
use Illuminated::Stand::Foe;
use Illuminated::Tile::GuardedSpace;

has players => (
    is => 'ro',
    default => sub { [ ] }
);
has foes => (
    is => 'ro',
    default => sub { [ ] }
);
has current_tile => (
    is => 'rw',
    default => undef,
);

sub init
{
    my $self = shift;
    my %player_templates = (
        'Maverick' => {
            health => 10,
            power => 3,
            speed => 2,
            mind => 1,
        },
        'Tesla' => {
            health => 10,
            power => 1,
            speed => 1,
            mind => 3,
        }
    );

    my %foe_templates = (
        thug => {
            health => 2,
            type => 'thug'
        },
        gunner => {
            health => 2,
            type => 'gunner',
        }
    );

    $self->add_player('Paladin', 'Maverick', $player_templates{'Maverick'});
    $self->add_player('Templar', 'Tesla', $player_templates{'Tesla'});
    $self->add_foe('Alpha', 'Thug');
    $self->add_foe('Beta', 'Thug');
    $self->add_foe('Gamma', 'Thug');
    $self->add_foe('Epsilon', 'Thug');
    $self->add_foe('Delta', 'Thug');
    $self->add_foe('Ro', 'Thug');
    $self->add_foe('Iota', 'Thug');

    $self->show_armies;

    $self->current_tile(Illuminated::Tile::GuardedSpace->new());

    my $fighting = 1;
    my $answer;
    while($fighting)
    { 
        if(! $self->current_tile->running)
        {
            while(! $answer)
            {
                $answer = $self->current_tile->gate_interface
            }
        }
    }

}

sub add_player
{
    my $self = shift;
    my $name = shift;
    my $type = shift;
    my $template = shift;

    $template->{name} = $name;
    $template->{type} = $type;
   
    my $pl = Illuminated::Stand::Player->new($template);
    push @{$self->players}, $pl;
}

sub add_foe
{
    my $self = shift;
    my $name = shift;
    my $type = shift;

    my $f = Illuminated::Stand::Foe->new({ name => $name, type => $name });
    push @{$self->foes}, $f;
}

sub show_armies
{
    my $self = shift;
    say "Players:";
    for(@{$self->players})
    {
        say "   " . $_->name;
    }
    print "\n";
    say "Foes:";
    for(@{$self->foes})
    {
        say "   " . $_->name;
    }
}

1;
