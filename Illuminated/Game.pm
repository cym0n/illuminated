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
has foe_templates => (
    is => 'ro',
    default => sub { {
        thug => {
            health => 2,
            type => 'thug'
        },
        gunner => {
            health => 2,
            type => 'gunner',
        }
    } } 
);
has distance_matrix => (
    is => 'ro',
    default => sub { {} }
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

    $self->current_tile(Illuminated::Tile::GuardedSpace->new());

    my $fighting = 1;
    my $answer;
    while($fighting)
    { 
        if(! $self->current_tile->running)
        {
            while(! $answer)
            {
                $answer = $self->current_tile->gate_choice()
            }
            $self->current_tile->gate_run($self, $self->get_player('Paladin'), $answer);
            $answer = undef; #All the loop starts again if gate_run fails to put the tile in running mode
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

sub get_player
{
    my $self = shift;
    my $name = shift;
    my $tag = 'P-' . lc($name);
    for(@{$self->players})
    {
        return $_ if $_->tag eq $tag;
    }
    return undef;
}

sub add_foe
{
    my $self = shift;

    my $f = undef;
    my $name = shift;
    
    if(ref($name) eq 'Illuminated::Stand::Foe')
    {
        $f = $name;
    }
    else
    {
        my $type = shift;
        $f = Illuminated::Stand::Foe->new({ name => $name, type => $type, health => $self->foe_templates->{$type}->{health} });
    }
    push @{$self->foes}, $f;
    foreach(@{$self->players})
    {
        $self->distance_matrix->{$_->tag}->{$f->tag} = 'none'
    }
}
sub get_foe
{
    my $self = shift;
    my $name = shift;
    if($name)
    {
        my $tag = 'F-' . lc($name);
        for(@{$self->foes})
        {
            return $_ if $_->tag eq $tag;
        }
    }
    else
    {   
       return $self->foes->[rand @{$self->foes}]; 
    }
    return undef;
}
sub set_foe_distance
{
    my $self = shift;
    my $player = shift;
    my $foe = shift;
    my $distance = shift;
    my $pobj = $self->get_player($player);
    my $fobj = $self->get_foe($foe);
    $self->distance_matrix->{$pobj->tag}->{$fobj->tag} = $distance;
}
sub set_foe_far_from_all
{
    my $self = shift;
    my $f = shift;
    foreach(@{$self->players})
    {
        if($self->distance_matrix->{$_->tag}->{$f->tag} eq 'none')
        {
            $self->distance_matrix->{$_->tag}->{$f->tag} = 'far'
        }
    }
}
sub kill_foe
{
    my $self = shift;
    my $f = shift;
    $f->health(0);
    $f->active(0);
    say $f->name . " killed!";
    @{$self->foes} = grep { $_->tag ne $f->tag}  @{$self->foes};
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

sub dice
{
    my $self = shift;
    my $many = shift;
    my $silent = shift;
    my $sides = 6;
    my $result = 0;
    my @throws = ();
    my $out;

    for(my $i = 0; $i < $many; $i++)
    {
        my $throw = int(rand(6)) + 1;
        push @throws, $throw;
        $result = $throw if($throw > $result);
    }
    say join (" ", @throws) . " => " . $result if ! $silent;
    return $result;
}

1;
