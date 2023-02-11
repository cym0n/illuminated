package Illuminated::Game;

use v5.10;
use Moo;
use Data::Dumper;
use Illuminated::Weapon;
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
has player_templates => (
    is => 'ro',
    default => sub { {
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
    } }
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
        },
        gladiator => {
            health => 2,
            type => 'gladiator',
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
has system_options => (
    is => 'rw',
    default => sub { [
        ['(QUIT)', "Exit game"]
    ] }
);
has interface_options => (
    is => 'rw',
    default => sub {  [ 
        ['(S)( (.*))?', "[S]ituation"], 
        ['(A)( (.*))',  "[A]ttack enemy (mind try)"], 
        ['(C)( (.*))',  "[C]lose on enemy (speed try)"], 
        ['(F)( (.*))', "[F]ly away from enemies (speed try)"], 
    ] }
);
has interface_weapons => (
    is => 'rw',
    default => sub { {} }
);
has active_player => (
    is => 'rw',
    default => undef,
);
has weapon_templates => (
    is => 'ro',
    default => sub { {
        'balthazar' => {
            name => 'balthazar',
            type => 'rifle',
            try_type => 'mind',
            range => [ 'near' ],
            damage => 1
        },
        'caliban' => {
            name => 'caliban',
            type => 'sword',
            try_type => 'power',
            range => [ 'close' ],
            damage => 2
        },
        'reiter' => {
            name => 'reiter',
            type => 'rifle',
            try_type => 'mind',
            range => [ 'far' ],
            damage => 1
        },
        'aegis' => {
            name => 'aegis',
            type => 'shield',
            try_type => 'power',
            range => [ ],
            damage => 0
        }
    } }
);
has loaded_dice => (
    is => 'ro',
    default => sub { [] }
);
has loaded_dice_counter => (
    is => 'rw',
    default => 0
);
has running => (
    is => 'rw',
    default => 1
);



with 'Illuminated::Role::Interactive';
with 'Illuminated::Role::Logger';

sub standard_game
{
    my $self = shift;
    $self->init_log;
    my $auto_commands = shift;
    my $player;
    $player = $self->add_player('Paladin', 'Maverick', $self->player_templates->{'Maverick'});
    $player->add_weapon(Illuminated::Weapon->new($self->weapon_templates->{'balthazar'}));
    $player->add_weapon(Illuminated::Weapon->new($self->weapon_templates->{'caliban'}));
    $player = $self->add_player('Templar', 'Tesla', $self->player_templates->{'Tesla'});
    $player->add_weapon(Illuminated::Weapon->new($self->weapon_templates->{'balthazar'}));
    $player->add_weapon(Illuminated::Weapon->new($self->weapon_templates->{'caliban'}));
    $self->current_tile(Illuminated::Tile::GuardedSpace->new());
}

sub run
{
    my $self = shift;
    my $answer;
    my $arg;
    $self->log("The game is on");
    while($self->running)
    { 
        if(! $self->current_tile->entered)
        {
            $self->current_tile->init_foes($self);
            my $i = 0;
            while($self->players->[$i] && $self->running)
            {
                $self->active_player($self->players->[$i]);
                $self->log("\nACTIVE PLAYER: " . $self->active_player->name);
                while(! $answer)
                {
                    ($answer, $arg) = $self->current_tile->choice($self)
                }
                my $res = $self->system_commands($answer, $arg) || $self->current_tile->gate_run($self, $self->active_player, $answer);
                if($res)
                {
                    $i++;
                }
                $answer = undef; 
            }
            $self->current_tile->entered(1);
        }
        else
        {
            my $i = 0;
            while($self->players->[$i] && $self->running)
            {
                $self->active_player($self->players->[$i]);
                $self->log("\nACTIVE PLAYER: " . $self->active_player->name);
                my $res = 0;
                while(! $answer)
                {
                    ($answer, $arg) = $self->choice($self)
                }
                $res = $self->system_commands($answer, $arg) || $self->standard_commands($answer, $arg);
                $answer = undef;
                $self->end_condition(); 
                if($res && $self->running)
                {
                    $self->foes_turn();
                    $self->end_condition(); 
                    $i++;
                }
            }
            if($self->running)
            {
                $self->assign_action_point();
                $self->foes_turn();
                $self->end_condition(); 
            }
        }
    }
}

sub standard_commands
{
    my $self = shift;
    my $answer = shift;
    my $arg = shift;
    if($answer eq 'S')
    {
        $self->situation($arg);
        return 0;
    }
    elsif($answer eq 'C')
    {
        $self->fly_closer($arg);
        return 1;
    }
    elsif($answer eq 'F')
    {
        $self->fly_away($arg);
        return 1;
    }
    elsif($answer =~ /^A\d+$/)
    {
        $self->attack_foe($answer, $arg);
        return 1;
    }
    elsif($answer eq 'D')
    {
        $self->disengage();
        return 1;
    }
    return 0;
}

sub system_commands
{
    my $self = shift;
    my $answer = shift;
    my $arg = shift;
    if($answer eq 'QUIT')
    {
        $self->log("Player quitted");
        $self->running(0);
        return 1;
    }
    return 0;
}

sub interface_preconditions
{
    my $self = shift;
    my $game = shift;

    my @options = (  ['^(S)( (.*))?$', "[S]ituation"] );
    my @ranges;
    if($game->at_distance($game->active_player, 'close'))
    {
        $self->interface_header("Combat zone - close combat");
        push @options, ['^(D)$', "[D]isengage (power try)"]; 
        @ranges = qw( close );
    }
    else
    {
        $self->interface_header("Combat zone");
        push @options, ['^(C)( (.*))$',  "[C]lose on enemy (speed try)"];
        push @options, ['^(F)( (.*))?$', "[F]ly away from enemies (speed try)"];
        @ranges = qw( far near );
    }
    my %already = ();
    my $i = 1;
    my %weapons_mapping = ();
    foreach my $d (@ranges)
    {
        if($game->at_distance($game->active_player, $d))
        {
            my @weaps = $game->active_player->get_weapons_by_range($d);
            foreach my $w (@weaps)
            {
                if(! exists $already{$w->name})
                {
                    push @options, ['^(A1)( (.*))?$', "[A" . $i . "]ttack enemy with " . $w->name . " (" . $w->try_type . " try)"];
                    $weapons_mapping{'A' . $i} = $w->name;
                    $i++
                }
            }
        }
    }
    $game->interface_options(\@options);
    $game->interface_weapons(\%weapons_mapping);
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
    return $pl;
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
    my $type = shift;
    my $weapons = shift;

    $f = Illuminated::Stand::Foe->new({ name => $name, type => $type, health => $self->foe_templates->{$type}->{health} });
    for(@{$weapons})
    {
        $f->add_weapon(Illuminated::Weapon->new($self->weapon_templates->{$_}));
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
sub detect_player_foe
{
    my $self = shift;
    my $a = shift;
    my $b = shift;
    my $player = undef;
    my $foe = shift;
    if(ref($a) eq 'Illuminated::Stand::Player')
    {
        $player = $a;
        $foe = $b;
    }
    elsif(ref($a) eq 'Illuminated::Stand::Foe')
    {
        $player = $b;
        $foe = $a;
    }
    return ($player, $foe);
}
sub set_distance
{
    my $self = shift;
    my $a = shift;
    my $b = shift;
    my ($player, $foe) = $self->detect_player_foe($a, $b);
    my $distance = shift;
    $self->distance_matrix->{$player->tag}->{$foe->tag} = $distance
}
sub get_distance
{
    my $self = shift;
    my $a = shift;
    my $b = shift;
    my ($player, $foe) = $self->detect_player_foe($a, $b);
    return $self->distance_matrix->{$player->tag}->{$foe->tag}
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

sub move
{
    my $self = shift;
    my $a = shift;
    my $b = shift;
    my ($player, $foe) = $self->detect_player_foe($a, $b);
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
sub at_distance
{
    my $self = shift;
    my $a = shift;
    my $distance = shift;
    my $random = shift;
    my ($player, $foe) = $self->detect_player_foe($a, undef);
    my $subject = undef;
    my @select;
    my @out = ();
    if($player)
    {
        $subject = $player;
        @select = @{$self->foes};
    }
    elsif($foe)
    {
        $subject = $foe;
        @select = @{$self->players};
    }
    for(@select)
    {
        push @out, $_ if($self->get_distance($subject, $_) eq $distance) 
    }
    if($random)
    {
        my $pick = $out[rand @out];
        return ( $pick );
    }
    else
    {
        return @out;
    }
}
sub harm_foe
{
    my $self = shift;
    my $attack_data = shift;
    $self->calculate_effects('before harm foe', $attack_data);

    $attack_data->{foe}->health($attack_data->{foe}->health - $attack_data->{damage});
    $self->log($attack_data->{foe}->name . " gets " . $attack_data->{damage} . " damages");;
    if($attack_data->{foe}->health <= 0)
    {
        $self->kill_foe($attack_data->{foe});
    }
    $self->calculate_effects('after harm foe', $attack_data);
}
sub harm_player
{
    my $self = shift;
    my $target = shift;
    my $damage = shift;
    $target->health($target->health - 1);
    $self->log($target->name . " receives $damage damages. " . $target->name . "'s health is now " . $target->health);
    if($target->health <= 0)
    {
        $self->log($target->name . " killed!");
        @{$self->players} = grep { $_->tag ne $target->tag } @{$self->players};
    }
}
sub kill_foe
{
    my $self = shift;
    my $f = shift;
    $f->health(0);
    $f->active(0);
    $self->log($f->name . " killed!");
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

sub throw_loaded_die
{
    my $self = shift;
    if($self->loaded_dice->[$self->loaded_dice_counter])
    {
        my $value = $self->loaded_dice->[$self->loaded_dice_counter];
        $self->loaded_dice_counter($self->loaded_dice_counter + 1);    
        return $value;
    }
    else
    {
        return undef;
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
        my $throw;
        if(my $loaded = $self->throw_loaded_die())
        {   
            $throw = $loaded;
        }
        else
        {
            $throw = int(rand(6)) + 1;
        }
        push @throws, $throw;
        $result = $throw if($throw > $result);
    }
    $self->log(join (" ", @throws) . " => " . $result) if ! $silent;
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
        $self->log($foe->name . " reaches " . $f->name . " and makes him aware!");
        $f->aware(1);
        $self->set_foe_far_from_all($f);
    }
    elsif($command eq 'away')
    {
        $self->log($foe->name . " steps away from " . $target->name . "!");
        $self->move($target, $foe, 'farther');
    }
    elsif($command eq 'attack')
    {
        $self->log($foe->name . " deals 1 damage to " . $target->name . "!");
        $self->harm_player($target, 1);
    }
    elsif($command eq 'pursuit')
    {
        $self->log($foe->name . " flyes to the " . $target->name . "!");
        $self->move($target, $foe, 'closer');
    }
    elsif($command eq 'parry')
    {
        $self->log($foe->name . " raises the aegis");
        $self->activate_foe_weapon($foe, $foe->get_weapon('aegis'), $target);
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
    $self->log("Action point given to: " . $foe->name);
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
                if($f->aware)
                {
                    $done = 1;
                    $f->action_points($f->action_points -1);
                    $f->ia($self);
                }
                else
                {
                    $self->log($f->name . " has action point but is unaware! Action point destroyed");
                    $done = 1;
                    $f->action_points($f->action_points -1);
                }
            }
        }
    }
}
sub end_condition
{
    my $self = shift;
    if(! @{$self->foes})
    {
        $self->log("VICTORY! All foes defeated");
        $self->running(0);
    }
    if(! @{$self->players})
    {
        $self->log("DEFEAT! Players destroyed");
        $self->running(0);
    }    
}
sub calculate_effects
{
    my $self = shift;
    my $event = shift;
    my $data = shift;
    my @triggering;
    if( $event eq 'before harm foe' ||
        $event eq 'after harm foe'     )
    {
        @triggering = ($data->{foe}, $data->{weapon}, $data->{attacker});
    }
    for(@triggering)
    {
        $_->calculate_effects($self, $event, $data);
    }
}
sub activate_foe_weapon
{
    my $self = shift;
    my $foe = shift;
    my $weapon = shift;
    my $target = shift;
    if($weapon->name eq 'aegis')
    {
        $foe->activate_status('parry');
    }
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
            $self->log("Wrong player");
            return 0;
        }
    }
    else
    {
        $p = $self->active_player;
    }
    print "\n";
    $self->log($p->name . ": HEALTH " . $p->health);
    print "\n";
    foreach my $f (@{$self->foes})
    {
        $self->log($f->description . " <" . $self->get_distance($p, $f) . ">");
    }
    print "\n";
    return 0;
}

sub fly_closer
{
    my $self = shift;
    my $fname = shift;
    my $foe = $self->get_foe($fname);
    if(! $foe) { $self->log("$fname doesn't exists or is inactive"); return 0 }
    if(! $foe->aware) { $self->log("$fname " . $foe->aware_text); return 0 }
    my ( $cl ) = $self->at_distance($foe, 'close', 1);
    if($cl && $self->get_distance($self->active_player, $foe) eq 'near') { $self->log("$fname already close to " . $cl->name); return 0}
    $self->log("Flying closer to $fname (speed try)");
    my $throw = $self->dice($self->active_player->speed);
    if($throw >= 5)
    {
        $self->log("Successfull approach");
        $self->move($self->active_player, $foe, 'closer');
        $self->log($foe->name . " now " . $self->get_distance($self->active_player, $foe) . " for " . $self->active_player->name); 
    }
    elsif($throw >= 3)
    {
        $self->log("Successfull approach with consequences");
        $self->move($self->active_player, $foe, 'closer');
        $self->log($foe->name . " now " . $self->get_distance($self->active_player, $foe) . " for " . $self->active_player->name);
        $self->assign_action_point($foe);
    }
    else
    {
        $self->log("Failed to approach!");
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
        if(! $self->at_distance($self->active_player, 'near')) { $self->log("Nobody is near"); return 0 }
        $self->log("Flying away from all enemies (speed try)");
        @targets = ( @{$self->foes} );
    }
    else
    {
        my $f = $self->get_foe($who);
        if(! $f) { $self->log("$who doesn't exists or is not active"); return 0 }
        if($self->get_distance($self->active_player, $f) ne 'near') { $self->log("$who is not near"); return 0 }
        $self->log("Flying away from $who (speed try)");
        @targets = ( $f );
    }
    my $throw = $self->dice($self->active_player->speed);
    if($throw >= 5)
    {
        $self->log("Successfully escaped!");
        foreach my $f ( @targets )
        {
            $self->move($self->active_player, $f, 'farther');
            $self->log($f->name . " now " . $self->get_distance($self->active_player, $f) . " for " . $self->active_player->name); 
        }
    }
    elsif($throw >= 3)
    {
        $self->log("Uncomplete escape! Rolling enemies one by one");
        foreach my $f ( @targets )
        {
            my $d = $self->get_distance($self->active_player, $f);
            if($d ne 'far' && $d ne 'none')
            { 
                my $throw = $self->dice(1);
                if($throw >= 5)
                {
                    $self->move($self->active_player, $f, 'farther');
                    $self->log($f->name . " now " . $self->get_distance($self->active_player, $f) . " for " . $self->active_player->name); 
                }
                elsif($throw >= 3)
                {
                    $self->log($f->name . " still $d for " . $self->active_player->name)
                }
                else
                {
                    $self->log($f->name . " still $d for " . $self->active_player->name . " with consequences");
                    $self->assign_action_point($f);
                }
            }
        }
    }
    else
    {
        $self->log("Failed to escape!");
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
    my $answer = shift;
    my $foe = undef;

    my $w = $self->active_player->get_weapon($self->interface_weapons->{$answer});

    my $combat_type = undef;
    ( $foe ) = $self->at_distance($self->active_player, 'close', 1);
    if(! $foe)
    {
        my $fname = shift;
        $foe = $self->get_foe($fname);
        if(! $foe) { $self->log("$fname doesn't exists or is not active"); return 0 }
        $combat_type = 'ranged';
    }
    else
    {
        $combat_type = 'close';
    }
    if(! $w->good_for_range($self->get_distance($self->active_player, $foe))) { $self->log("Distance not suitable"); return 0 };
    
    $self->log("Attacking " . $foe->name . " with " . $w->name . " (" . $w->try_type . " try)");
    my $try = $w->try_type;
    my $damage = $w->damage;
    my $throw = $self->dice($self->active_player->$try);
    my %attack_data = (
        attacker => $self->active_player,
        weapon => $w,
        foe => $foe,
        damage => $damage,
        throw => $throw 
    );


    if($throw >= 5)
    {
        $self->log("Successful attack!");
        $self->harm_foe(\%attack_data);
    }
    elsif($throw >= 3)
    {
        $self->log("Successful attack with consequences!");
        $self->harm_foe(\%attack_data);
        $self->assign_action_point($foe);
    }
    else
    {
        $self->log("Attack failed!");
        $self->assign_action_point($foe);
    }
    return 1;
}

sub disengage
{
    my $self = shift;
    my ( $foe ) = $self->at_distance($self->active_player, 'close', 1);
    if(! $foe) { $self->log("Nobody close to " . $self->active_player->name); return 0 };
    $self->log("Disengaging from " . $foe->name . " (power try)");
    my $throw = $self->dice($self->active_player->power);
    if($throw >= 5)
    {
        $self->log("Successfully disengaged!");
        $self->move($self->active_player, $foe, 'farther');
    }
    elsif($throw >= 3)
    {
        $self->log("Disengaged with consequences");
        $self->move($self->active_player, $foe, 'farther');
        $self->assign_action_point($foe);
    }
    else
    {
        $self->log("Disengaging failed!");
        $self->assign_action_point($foe);
    }
    return 1;
}


1;
