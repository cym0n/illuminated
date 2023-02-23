package Illuminated::Game;

use v5.10;
use Moo;
use Data::Dumper;
use Illuminated::Weapon;
use Illuminated::Device::Jammer;
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
            energy => 5,
            power => 3,
            speed => 2,
            mind => 1,
        },
        'Tesla' => {
            health => 10,
            energy => 5,
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
has interface_devices => (
    is => 'rw',
    default => sub { {} }
);
has active_player_counter => (
    is => 'rw',
    default => 0
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
    is => 'rw',
    default => sub { [] }
);
has loaded_dice_counter => (
    is => 'rw',
    default => 0
);
has random_dice_counter => (
    is => 'rw',
    default => 0
);
has fake_random => (
    is => 'rw',
    default => sub { [] }
);
has fake_random_counter => (
    is => 'rw',
    default => 0
);
has true_random_counter => (
    is => 'rw',
    default => 0
);
has running => (
    is => 'rw',
    default => 1
);



with 'Illuminated::Role::Interactive';
with 'Illuminated::Role::Logger';

sub init_test
{
    my $package = shift;
    my $game_start = shift;
    my $loaded_dice = shift;
    my $fake_random = shift;
    my $auto_commands = shift;
    my $game = Illuminated::Game->new(
        {   loaded_dice => $loaded_dice, 
            auto_commands => $auto_commands,
            fake_random => $fake_random,
            log_prefix => 'test',
        }
    );
    $game->log_prefix('test');
    $game->$game_start;
    return $game;
}

sub configure_scenario
{
    my $self = shift;
    my $loaded_dice = shift;
    my $fake_random = shift;
    my $auto_commands = shift;
    $self->loaded_dice($loaded_dice);
    $self->loaded_dice_counter(0);
    $self->auto_commands($auto_commands);
    $self->auto_commands_counter(0);
    $self->fake_random($fake_random);
    $self->fake_random_counter(0);
    $self->running(1);
}

sub standard_test
{
    my $package = shift;

    my $game = $package->init_test('standard_game', 
                                    [6, 6, 6, 4, 2, 4, 2, 2, 2,
                                     6, 6, 6, 4, 2, 4, 2, 2, 2,], 
                                    [8, 4], 
                                    ['N', 'N', 'quit']);
    $game->run();
    $game->log("========== STANDARD TEST GENERATION ENDED ==============");
    return $game;
}

sub standard_game
{
    my $self = shift;
    $self->init_log;
    my $player;
    $player = $self->add_player('Paladin', 'Maverick', $self->player_templates->{'Maverick'});
    $player->add_weapon(Illuminated::Weapon->new($self->weapon_templates->{'balthazar'}));
    $player->add_weapon(Illuminated::Weapon->new($self->weapon_templates->{'caliban'}));
    $player->add_device(Illuminated::Device::Jammer->new());
    $player = $self->add_player('Templar', 'Tesla', $self->player_templates->{'Tesla'});
    $player->add_weapon(Illuminated::Weapon->new($self->weapon_templates->{'balthazar'}));
    $player->add_weapon(Illuminated::Weapon->new($self->weapon_templates->{'caliban'}));
    $self->current_tile(Illuminated::Tile::GuardedSpace->new());
}

sub active_player
{
    my $self = shift;
    return $self->players->[$self->active_player_counter];
}
sub next_player
{
    my $self = shift;
    $self->active_player_counter($self->active_player_counter + 1);
}
sub reset_player_counter
{
    my $self = shift;
    $self->active_player_counter(0);
}

sub run
{
    my $self = shift;
    my $answer;
    my $arg;
    $self->log("=== RUN ===");
    while($self->running)
    { 
        if(! $self->current_tile->entered)
        {
            $self->log("Entering tile phase");
            $self->current_tile->init_foes($self);
            $self->reset_player_counter();
            while($self->active_player && $self->running)
            {
                $self->log("\nACTIVE PLAYER: " . $self->active_player->name);
                while(! $answer)
                {
                    ($answer, $arg) = $self->current_tile->choice($self)
                }
                my $res = $self->system_commands($answer, $arg) || $self->current_tile->gate_run($self, $self->active_player, $answer);
                if($res)
                {
                    $self->next_player();
                }
                $answer = undef; 
            }
            $self->reset_player_counter();
            $self->current_tile->entered(1);
        }
        else
        {
            $self->log("combat phase");
            while($self->active_player && $self->running)
            {
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
                    $self->next_player();
                }
            }
            if($self->running)
            {
                $self->assign_action_point();
                $self->foes_turn();
                $self->end_condition(); 
                $self->clock();
                $self->reset_player_counter();
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
    elsif($answer =~ /^P\d+$/)
    {
        $self->use_device($answer, $arg);
        return 0; #Device use doesn't imply end of turn
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
    my %devices_mapping = ();
    foreach my $d (@ranges)
    {
        if($game->at_distance($game->active_player, $d))
        {
            my @weaps = $game->active_player->get_weapons_by_range($d);
            foreach my $w (@weaps)
            {
                if(! exists $already{$w->name})
                {
                    push @options, ['^(A' . $i. ')( (.*))?$', "[A" . $i . "]ttack enemy with " . $w->name . " (" . $w->try_type . " try)"];
                    $weapons_mapping{'A' . $i} = $w->name;
                    $i++
                }
            }
        }
    }
    $i = 1;
    foreach my $d(@{$self->active_player->devices})
    {
        if($d->preconditions($self, $self->active_player))
        {
            push @options, ['^(P' . $i. ')( (.*))?$', "[P" . $i . "]ower: " . $d->name];
            $devices_mapping{'P' . $i} = $d->name;
            $i++;
        }
    }
    $game->interface_options(\@options);
    $game->interface_weapons(\%weapons_mapping);
    $game->interface_devices(\%devices_mapping);
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
       return $self->foes->[$self->game_rand( @{$self->foes})]; 
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
    if($random && @out)
    {
        if(@out == 1)
        {
            return @out;
        }
        else
        {
            my $pick = $out[$self->game_rand( @out )];
            return ( $pick );
        }
    }
    else
    {
        return @out;
    }
}
sub harm
{
    my $self = shift;
    my $attacker = shift;
    my $defender = shift;
    my $damage = shift;

    $defender->harm($damage);

    $self->log($defender->name . " gets " . $damage . " damages");;
    if($defender->health <= 0)
    {
        $self->kill($defender);
    }
}
sub kill
{
    my $self = shift;
    my $s = shift;
    $s->health(0);
    $s->active(0);
    $self->log($s->name . " killed!");
    if(ref($s) eq 'Illuminated::Stand::Foe')
    {
        @{$self->foes} = grep { $_->tag ne $s->tag}  @{$self->foes};
    }
    elsif(ref($s) eq 'Illuminated::Stand::Player')
    {
        @{$self->players} = grep { $_->tag ne $s->tag } @{$self->players};
    }
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

sub game_rand
{
    my $self = shift;
    my @input = @_;
    my $number = undef;
    if($#input == 0)
    { 
        $number = $input[0];
    }
    else
    {
        $number = @input;
    }
    $self->file_only("Random evoked, range $number");
    if(exists $self->fake_random->[$self->fake_random_counter])
    {
        my $value = $self->fake_random->[$self->fake_random_counter];
        $self->log("Random tampered. Range $number, result $value");
        $self->fake_random_counter($self->fake_random_counter + 1);    
        return $value;
    }
    else
    {
        $self->true_random_counter($self->true_random_counter + 1);
        return int(rand $number);
    }

}


sub dice
{
    my $self = shift;
    my $many = shift;
    my $silent = shift;
    my $mods = shift;
    my $sides = 6;
    my $result = 0;
    my @throws = ();
    my $out;

    for(my $i = 0; $i < $many; $i++)
    {
        my $throw;
        if(my $loaded = $self->throw_loaded_die())
        {   
            $self->log("Loaded die");
            $throw = $loaded;
        }
        else
        {
            $throw = int(rand(6)) + 1;
            $self->random_dice_counter($self->random_dice_counter + 1);
        }
        push @throws, $throw;
        $result = $throw if($throw > $result);
    }
    if($silent)
    {
        $self->file_only("Dice throw: " . join (" ", @throws) . " => " . $result);
    }
    else
    {
        $self->log("Dice throw: " . join (" ", @throws) . " => " . $result);
    }
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
        my $f = $unw[$self->game_rand(@unw)];
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
        $self->harm($foe, $target, 1);
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
        $foe = $self->foes->[$self->game_rand(@{$self->foes})];
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

    my @targets = ();

    if($data->{subject_2})
    {
        if(ref($data->{subject_2}) eq 'ARRAY')
        {
            @targets = @{$data->{subject_2}};
        }
        else
        {
            @targets = ( $data->{subject_2} );
        }
    }

    my @triggering = (@targets, $data->{weapon}, $data->{subject_1});
    foreach my $t (@triggering)
    {
        $t->calculate_effects($self, $event, $data) if $t;
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

sub device
{
    my $self = shift;
    my $subject = shift;
    my $d = shift;
    my $arg = shift;
    $subject->use_energy($d->energy_usage);
    $d->action($self, $subject, $arg);
}

sub clock
{
    my $self = shift;
    foreach my $p (@{$self->players})
    {
        $p->counters_clock($self);
    }
    foreach my $f (@{$self->foes})
    {
        $f->counters_clock($self);
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
    $self->log($p->name . ": HEALTH " . $p->health . ", ENERGY " . $p->energy);
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

    #Preconditions
    my $foe = $self->get_foe($fname);
    if(! $foe) { $self->log("$fname doesn't exists or is inactive"); return 0 }
    if(! $foe->aware) { $self->log("$fname " . $foe->aware_text); return 0 }
    my ( $cl ) = $self->at_distance($foe, 'close', 1);
    if($cl && $self->get_distance($self->active_player, $foe) eq 'near') { $self->log("$fname already close to " . $cl->name); return 0}

    #Data
    my $data = {
        subject_1 => $self->active_player,
        subject_2 => $foe,
        direction => 'closer',
        try_type => 'speed',
        command => 'fly_closer',
        call => 'play_move',
    };

    #Announcement
    $self->log("Flying closer to $fname (speed try)");

    #Action
    my $outcome = $self->play_command($data);
    if($outcome == 2)
    {
        $self->log("Successful approach");
        $self->log($foe->name . " now " . $self->get_distance($self->active_player, $foe) . " for " . $self->active_player->name); 
    }
    elsif($outcome == 1)
    {
        $self->log("Successful approach with consequences");
        $self->log($foe->name . " now " . $self->get_distance($self->active_player, $foe) . " for " . $self->active_player->name);
        $self->assign_action_point($foe);
    }
    elsif($outcome == 0)
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

    #Preconditions and announcement
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

    #Data
    my $data = {
        subject_1 => $self->active_player,
        subject_2 => \@targets,
        direction => 'farther',
        try_type => 'speed',
        command => 'fly_away',
        call => 'play_move',
    };

    #Action
    my $outcome = $self->play_command($data);
    if($outcome == 2)
    {
        $self->log("Successfully escaped!");
        foreach my $f ( @targets )
        {
            $self->log($f->name . " now " . $self->get_distance($self->active_player, $f) . " for " . $self->active_player->name); 
        }
    }
    elsif($outcome == 1)
    {
        $self->log("Uncomplete escape! Rolling enemies one by one");
        foreach my $f ( @targets )
        {
            my $d = $self->get_distance($self->active_player, $f);
            $self->log($f->name . " now " . $self->get_distance($self->active_player, $f) . " for " . $self->active_player->name); 
            if($f->action_points > 0)
            {
                $self->log($f->name . " has " . $f->action_points . " action points");
            }
        }
    }
    elsif($outcome == 0)
    {
        $self->log("Failed to escape! (all enemies gain an action point");
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

sub disengage
{
    my $self = shift;

    #Preconditions
    my ( $foe ) = $self->at_distance($self->active_player, 'close', 1);
    if(! $foe) { $self->log("Nobody close to " . $self->active_player->name); return 0 };
    
    #Announcement
    $self->log("Disengaging from " . $foe->name . " (power try)");

    #data
    my $data = {
        subject_1 => $self->active_player,
        subject_2 => $foe,
        direction => 'farther',
        try_type => 'speed',
        command => 'disengage',
        call => 'play_move',
    };

    #Action
    my $outcome = $self->play_command($data);

    if($outcome == 2)
    {
        $self->log("Successfully disengaged!");
        $self->move($self->active_player, $foe, 'farther');
    }
    elsif($outcome == 1)
    {
        $self->log("Disengaged with consequences");
        $self->assign_action_point($foe);
    }
    elsif($outcome == 0)
    {
        $self->log("Disengaging failed!");
    }
    return 1;
}

sub attack_foe
{
    my $self = shift;
    my $answer = shift;
    my $foe = undef;

    #Precoditions
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

    #Announcement
    $self->log("Attacking " . $foe->name . " with " . $w->name . " (" . $w->try_type . " try)");
    
    #Data
    my $data = {
        subject_1 => $self->active_player,
        subject_2 => $foe,
        combat_type => $combat_type,
        try_type => $w->try_type,
        command => 'attack',
        weapon => $w,
        damage => $w->damage,
        call => 'play_harm',
    };

    #Action
    my $outcome = $self->play_command($data);

    if($outcome == 2)
    {
        $self->log("Successful attack!");
    }
    elsif($outcome == 1)
    {
        $self->log("Successful attack with consequences!");
        $self->assign_action_point($foe);
    }
    elsif($outcome == 0)
    {
        $self->log("Attack failed!");
        $self->assign_action_point($foe);
    }
    return 1;
}

sub use_device
{
    my $self = shift;
    my $answer = shift;
    my $arg = shift;

    #Preconditions
    my $d = $self->active_player->get_device($self->interface_devices->{$answer});
    if(! $d) { $self->log("$answer not mapped on suitable device"); return 0 }
    if(! $d->preconditions($self, $self->active_player, $arg)) { $self->log($d->name . " cannot be used"); return 0 }; 

    #Announcement
    $self->log("Using " . $d->name);

    #Data
    my $data = {
        subject_1 => $self->active_player,
        arg => $arg, #Too generic to be reduced to foe
        try_type => undef, #Always success
        device => $d,
        command => 'device',
        call => 'play_device',
    };
    
    #Action
    my $outcome = $self->play_command($data);
    
    #No need to check outcome, always 2

    return 1;
}



# Commands support subs

sub play_command
{
    my $self = shift;
    my $data = shift;

    my $throw = undef;
    if($data->{try_type})
    {
        my $try = $data->{try_type};
        $self->calculate_effects("dice " . $data->{command}, $data);
        $throw = $self->dice($data->{subject_1}->$try, 0, $data->{dice_mods});
    }
    my $outcome;
    if( (defined $throw && $throw >= 5) || (! defined $throw))
    {
        $outcome = 2; #success
    }
    elsif( defined $throw && $throw >= 3)
    {
        $outcome = 1; #success with consequences
    }
    else
    {
        return 0; #failure
    }
    $data->{outcome} = $outcome;
    $self->calculate_effects("before " . $data->{command}, $data);
    my $call = $data->{call};
    $self->$call($data);
    $self->calculate_effects("after " . $data->{command}, $data);
    return $outcome;
}

sub play_move
{
    my $self = shift;
    my $data = shift;
    if(ref($data->{subject_2}) eq 'ARRAY')
    {
        if($data->{direction} eq 'farther')
        {
            foreach my $f ( @{$data->{subject_2}} )
            {
                my $d = $self->get_distance($data->{subject_1}, $f);
                if($d ne 'far' && $d ne 'none')
                { 
                    if($data->{'outcome'} == 2)
                    {
                        $self->move($data->{subject_1}, $f, 'farther');
                    }
                    else
                    {
                        my $throw = $self->dice(1);
                        if($throw >= 5)
                        {
                            $self->move($data->{subject_1}, $f, 'farther');
                        }
                        elsif($throw >= 3)
                        {
                        }
                        else
                        {
                            $self->assign_action_point($f);
                        }
                    }
                }
            }
        }
    }
    else
    {
        $self->move($data->{subject_1}, $data->{subject_2}, $data->{direction});
    }
}

sub play_harm
{
    my $self = shift;
    my $data = shift;
    $self->harm($data->{subject_1}, $data->{subject_2}, $data->{damage});
}

sub play_device
{
    my $self = shift;
    my $data = shift;
    $self->device($data->{subject_1}, $data->{device}, $data->{arg});
}

1;
