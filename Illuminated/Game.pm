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

has interface_header => (
    is => 'rw',
    default => "Combat zone"
);
has interface_options => (
    is => 'rw',
    default => sub {  [ 
        ['^(S)( (.*))?$', "[S]ituation"], 
        ['^(A)( (.*))$',  "[A]ttack enemy (mind try)"], 
        ['^(C)( (.*))$',  "[C]lose on enemy (speed try)"], 
        ['^(F)( (.*))?$', "[F]ly away from enemies (speed try)"], 
    ] }
);
has active_player => (
    is => 'rw',
    default => undef,
);

with 'Illuminated::Role::Interactive';

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
    my $arg;
    while($fighting)
    { 
        if(! $self->current_tile->running)
        {
            $self->current_tile->init_foes($self);
            my $i = 0;
            while($self->players->[$i])
            {
                $self->active_player($self->players->[$i]);
                say "\nACTIVE PLAYER: " . $self->active_player->name;
                while(! $answer)
                {
                    ($answer, $arg) = $self->current_tile->choice($self)
                }
                my $res = $self->current_tile->gate_run($self, $self->active_player, $answer);
                if($res)
                {
                    $i++;
                }
                $answer = undef; 
            }
            $self->current_tile->running(1);
        }
        else
        {
            my $i = 0;
            while($self->players->[$i])
            {
                $self->active_player($self->players->[$i]);
                say "\nACTIVE PLAYER: " . $self->active_player->name;
                my $res = 0;
                while(! $answer)
                {
                    ($answer, $arg) = $self->choice($self)
                }
                if($answer eq 'S')
                {
                    $res = $self->situation($arg);
                }
                elsif($answer eq 'C')
                {
                    $res = $self->fly_closer($arg);
                }
                elsif($answer eq 'F')
                {
                    $res = $self->fly_away($arg);
                }
                elsif($answer eq 'A')
                {
                    $res = $self->attack_foe($arg);
                }
                elsif($answer eq 'D')
                {
                    $res = $self->disengage();
                }
                $answer = undef;
                $fighting = $self->end_condition(); 
                if($res && $fighting)
                {
                    $self->foes_turn();
                    $fighting = $self->end_condition(); 
                    $i++;
                }
            }
            if($fighting)
            {
                $self->assign_action_point();
                $self->foes_turn();
                $fighting = $self->end_condition(); 
            }
        }
    }
}

sub interface_preconditions
{
    my $self = shift;
    my $game = shift;
    if($game->someone_close($game->active_player))
    {
        $self->interface_header("Combat zone - close combat");
        $self->interface_options([ 
            ['^(S)( (.*))?$', "[S]ituation"], 
            ['^(A)( (.*))?$', "[A]ttack enemy (mind try)"], 
            ['^(D)$', "[D]isengage (power try)"], 
            ]);
    }
    else
    {
        $self->interface_header("Combat zone");
        $self->interface_options([ 
            ['^(S)( (.*))?$', "[S]ituation"], 
            ['^(A)( (.*))$',  "[A]ttack enemy (mind try)"], 
            ['^(C)( (.*))$',  "[C]lose on enemy (speed try)"], 
            ['^(F)( (.*))?$', "[F]ly away from enemies (speed try)"], 
            ]);
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
        $self->set_distance($_, $f, 'none');
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
    $self->set_distance($pobj, $fobj, $distance);
}
sub set_foe_far_from_all
{
    my $self = shift;
    my $f = shift;
    foreach(@{$self->players})
    {
        if($self->get_distance($_, $f) eq 'none')
        {
            $self->set_distance($_, $f, 'far')
        }
    }
}
sub set_distance
{
    my $self = shift;
    my $player = shift;
    my $foe = shift;
    my $distance = shift;
    $self->distance_matrix->{$player->tag}->{$foe->tag} = $distance
}
sub get_distance
{
    my $self = shift;
    my $player = shift;
    my $foe = shift;
    return $self->distance_matrix->{$player->tag}->{$foe->tag}
}
sub move
{
    my $self = shift;
    my $player = shift;
    my $foe = shift;
    my $direction = shift;
    if($direction eq 'farther')
    {
        if($self->get_distance($player, $foe) eq 'close')
        {
            $self->set_distance($player, $foe, 'near');
        }
        elsif($self->get_distance($player, $foe) eq 'near')
        {
            $self->set_distance($player, $foe, 'far');
        }
    }
    elsif($direction eq 'closer')
    {
        if($self->get_distance($player, $foe) eq 'near')
        {
            $self->set_distance($player, $foe, 'close');
        }
        elsif($self->get_distance($player, $foe) eq 'far')
        {
            $self->set_distance($player, $foe, 'near');
        }
    }
}

sub foe_distance
{
    my $self = shift;
    my $foe = shift;
    my $distance = shift;
    my @pls = ();
    foreach(@{$self->players})
    {
        if($self->get_distance($_, $foe) eq $distance) { push @pls, $_; };
    }
    return @pls;
}

sub close_to
{
    my $self = shift;
    my $foe = shift;
    foreach(@{$self->players})
    {
        if($self->get_distance($_, $foe) eq 'close') { return $_ };
    }
    return undef;
}
sub someone_near
{
    my $self = shift;
    my $player = shift;
    return $self->_someone_distance($player, 'near')
}
sub someone_close
{
    my $self = shift;
    my $player = shift;
    return $self->_someone_distance($player, 'close')
}
sub _someone_distance
{
    my $self = shift;
    my $player = shift;
    my $distance = shift;
    foreach(@{$self->foes})
    {
        if($self->get_distance($player, $_) eq $distance) { return $_ };
    }
    return undef;
}
sub harm_foe
{
    my $self = shift;
    my $foe = shift;
    my $damage = shift;
    $foe->health($foe->health - $damage);
    say $foe->name . " gets $damage damages";
    if($foe->health <= 0)
    {
        $self->kill_foe($foe);
    }
}

sub harm_player
{
    my $self = shift;
    my $target = shift;
    my $damage = shift;
    $target->health($target->health - 1);
    say $target->name . " receives $damage damages. " . $target->name . "'s health is now " . $target->health;
    if($target->health <= 0)
    {
        say $target->name . " killed!";
        @{$self->players} = grep { $_->tag ne $target->tag } @{$self->players};
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

sub aware_foe
{
    my $self = shift;
    for(@{$self->foes})
    {
        return 1 if $_->aware;
    }
    return 0;
}

sub unaware_foe
{
    my $self = shift;
    my @unw = ();
    for(@{$self->foes})
    {
        push @unw, $_ if ! $_->aware;
    }
    return @unw;
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

sub execute_foe
{
    my $self = shift;
    my $foe = shift;
    my $command = shift;
    my $target = shift;

    if($command eq 'warn')
    {
        my @unw = $self->unaware_foe();
        my $f = $unw[rand @unw];
        say $foe->name . " reaches " . $f->name . " and makes him aware!";
        $f->aware(1);
        $self->set_foe_far_from_all($f);
    }
    elsif($command eq 'away')
    {
        say $foe->name . " steps away from " . $target->name . "!";
        $self->move($target, $foe, 'farther');
    }
    elsif($command eq 'attack')
    {
        say $foe->name . " deals 1 damage to " . $target->name . "!";
        $self->harm_player($target, 1);
    }
    elsif($command eq 'pursuit')
    {
        say $foe->name . " flyes to the " . $target->name . "!";
        $self->move($target, $foe, 'closer');
    }
}

sub assign_action_point
{
    my $self = shift;
    my $foe = shift;
    if(! $foe || ! $foe->active)
    {
        $foe = $self->foes->[rand @{$self->foes}];
    }
    $foe->action_points($foe->action_points + 1);
    say "Action point given to: " . $foe->name;
}

sub foes_turn
{
    my $self = shift;
    my $done = 1;

    while($done)
    {
        $done = 0;
        foreach my $f (@{$self->foes})
        {
            if($f->action_points > 0)
            {
                $done = 1;
                $f->action_points($f->action_points -1);
                $f->ia($self);
            }
        }
    }
}

sub end_condition
{
    my $self = shift;
    if(! @{$self->foes})
    {
        say "VICTORY! All foes defeated";
        return 0;
    }
    if(! @{$self->players})
    {
        say "DEFEAT! Players destroyed";
        return 0;
    }    
    return 1;
}

### Combat commands

sub situation
{
    my $self = shift;
    my $who = shift;
    my $p;
    if($who)
    {
        $p = $self->get_player($who);
        if(! $p)
        {
            say "Wrong player";
            return 0;
        }
    }
    else
    {
        $p = $self->active_player;
    }
    print "\n";
    say $p->name . ": HEALTH " . $p->health;
    print "\n";
    foreach my $f (@{$self->foes})
    {
        say $f->name . " (" .  $f->type . "): HEALTH " . $f->health . " " . 
            join(" ", $f->aware_text, $self->get_distance($p, $f)); 
    }
    print "\n";
    return 0;
}

sub fly_closer
{
    my $self = shift;
    my $fname = shift;
    my $foe = $self->get_foe($fname);
    if(! $foe) { say "$fname doesn't exists or is inactive"; return 0 }
    if(! $foe->aware) { say "$fname " . $foe->aware_text; return 0 }
    if(my $cl = $self->close_to($foe)) { say "$fname already close to " . $cl->name; return 0}
    say "Flying closer to $fname (speed try)";
    my $throw = $self->dice($self->active_player->speed);
    if($throw >= 5)
    {
        say "Successfull approach";
        $self->move($self->active_player, $foe, 'closer');
        say $foe->name . " now " . $self->get_distance($self->active_player, $foe) . " for " . $self->active_player->name; 
    }
    elsif($throw >= 3)
    {
        say "Successfull approach with consequences";
        $self->move($self->active_player, $foe, 'closer');
        say $foe->name . " now " . $self->get_distance($self->active_player, $foe) . " for " . $self->active_player->name;
        $self->assign_action_point($foe);
    }
    else
    {
        say "Failed to approach!";
        $self->assign_action_point($foe);
    }
    return 1;
}

sub fly_away
{
    my $self = shift;
    my $who = shift;
    my @targets;
    if(lc($who) eq '_all')
    {
        if(! $self->someone_near($self->active_player)) { say "Nobody is near"; return 0 }
        say "Flying away from all enemies (speed try)";
        @targets = ( @{$self->foes} );
    }
    else
    {
        my $f = $self->get_foe($who);
        if(! $f) { say "$who doesn't exists or is not active"; return 0 }
        if($self->get_distance($self->active_player, $f) ne 'near') { say "$who is not near"; return 0 }
        say "Flying away from $who (speed try)";
        @targets = ( $f );
    }
    my $throw = $self->dice($self->active_player->speed);
    if($throw >= 5)
    {
        say "Successfully escaped!";
        foreach my $f ( @targets )
        {
            $self->move($self->active_player, $f, 'farther');
            say $f->name . " now " . $self->get_distance($self->active_player, $f) . " for " . $self->active_player->name; 
        }
    }
    elsif($throw >= 3)
    {
        say "Uncomplete escape! Rolling enemies one by one";
        foreach my $f ( @targets )
        {
            my $d = $self->get_distance($self->active_player, $f);
            if($d ne 'far' && $d ne 'none')
            { 
                my $throw = $self->dice(1);
                if($throw >= 5)
                {
                    $self->move($self->active_player, $f, 'farther');
                    say $f->name . " now " . $self->get_distance($self->active_player, $f) . " for " . $self->active_player->name; 
                }
                elsif($throw >= 3)
                {
                    say $f->name . " still $d for " . $self->active_player->name
                }
                else
                {
                    say $f->name . " still $d for " . $self->active_player->name . " with consequences";
                    $self->assign_action_point($f);
                }
            }
        }
    }
    else
    {
        say "Failed to escape!";
        foreach my $f ( @targets )
        {
            my $d = $self->get_distance($self->active_player, $f);
            if($d ne 'far' && $d ne 'none')
            {
                $self->assign_action_point($f);
            }
        }
    }
    return 1;
}

sub attack_foe
{
    my $self = shift;
    my $foe = undef;
    my $combat_type = undef;
    $foe = $self->someone_close($self->active_player);
    if(! $foe)
    {
        my $fname = shift;
        $foe = $self->get_foe($fname);
        if(! $foe) { say "$fname doesn't exists or is not active"; return 0 }
        if($self->get_distance($self->active_player, $foe) ne 'near') { say "$fname too far"; return 0 }
        $combat_type = 'ranged';
    }
    else
    {
        $combat_type = 'close';
    }
    
    my $try;
    my $damage;
    if( $combat_type eq 'ranged' )
    {
        say "Attacking " . $foe->name . " with gun (mind try)";
        $try = $self->active_player->mind;
        $damage = 1;
    }
    elsif( $combat_type eq 'close')
    {
        say "Attacking " . $foe->name . " with sword (power try)";
        $try = $self->active_player->power;
        $damage = 2;
    }
    my $throw = $self->dice($try);
    if($throw >= 5)
    {
        say "Successful attack!";
        $self->harm_foe($foe, $damage);
    }
    elsif($throw >= 3)
    {
        say "Successful attack with consequences!";
        $self->harm_foe($foe, $damage);
        $self->assign_action_point($foe);
    }
    else
    {
        say "Attack failed!";
        $self->assign_action_point($foe);
    }
    return 1;
}

sub disengage
{
    my $self = shift;
    my $foe = $self->someone_close($self->active_player);
    if(! $foe) { say "Nobody close to " . $self->active_player->name; return 0 };
    say "Disengaging from " . $foe->name . " (power try)";
    my $throw = $self->dice($self->active_player->power);
    if($throw >= 5)
    {
        say "Successfully disengaged!";
        $self->move($self->active_player, $foe, 'farther');
    }
    elsif($throw >= 3)
    {
        say "Disengaged with consequences";
        $self->move($self->active_player, $foe, 'farther');
        $self->assign_action_point($foe);
    }
    else
    {
        say "Disengaging failed!";
        $self->assign_action_point($foe);
    }
    return 1;
}


1;
