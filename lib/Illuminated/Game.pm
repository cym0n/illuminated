package Illuminated::Game;

use v5.10;
use Moo;
use Data::Dumper;
use Illuminated::Weapon;
use Illuminated::Element::Stand::Player;
use Illuminated::Element::Stand::Foe;


has players => (
    is => 'ro',
    default => sub { [ ] }
);
has foes => (
    is => 'ro',
    default => sub { [ ] }
);
has others => (
    is => 'ro',
    default => sub { [] }
);
has current_tile => (
    is => 'rw',
    default => undef,
);
has distance_matrix => (
    is => 'ro',
    default => sub { {} }
);
has ground_position => (
    is => 'ro',
    default => sub { {} }
);
has active_player_counter => (
    is => 'rw',
    default => 0
);
has active_player_device_chance => (
    is => 'rw',
    default => 1
);

has turn => (
    is => 'rw',
    default => 0
);
has running => (
    is => 'rw',
    default => 1
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

with 'Illuminated::Role::Interactive::Game';
with 'Illuminated::Role::Logger';
with 'Illuminated::Role::Destiny';
with 'Illuminated::Role::Recorder';
with 'Illuminated::Role::Tester';

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
            $self->current_tile->init($self);
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
                    $self->active_player_device_chance(1);
                }
            }
            if($self->running)
            {
                $self->log("\nFOES TURN");
                for(my $i = 0; $i < $self->current_tile->end_turn_action_points; $i++) { $self->assign_action_point(); }
                $self->foes_turn();
                $self->end_condition(); 
                $self->clock();
                $self->reset_player_counter();
            }
        }
    }
    $self->log("Random dice: " . $self->random_dice_counter . " Random numbers: " . $self->true_random_counter);
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
        return $self->fly_closer($arg);
    }
    elsif($answer eq 'F')
    {
        return $self->fly_away($arg);
    }
    elsif($answer =~ /^A\d+$/)
    {
        return $self->attack_foe($answer, $arg);
    }
    elsif($answer =~ /^P\d+$/ && $self->active_player_device_chance)
    {
        my $outcome = $self->use_device($answer, $arg);
        $self->active_player_device_chance(0) if $outcome;
        return 0; #Device use doesn't imply end of turn
    }
    elsif($answer eq 'D')
    {
        return $self->disengage();
    }
    elsif($answer eq 'L')
    {
        if($self->on_ground($self->active_player))
        {
            return $self->lift();
        }
        else
        {
            return $self->land($arg);
        }
    }
    elsif($answer eq 'V')
    {
        return $self->cover($arg);
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
    elsif($answer eq 'INTERFACE')
    {
        $self->log("------- Logging interface...");
        $self->interface($self, 1);
    }
    elsif($answer eq 'DUMP')
    {
        my $obj = $self->get_player($arg);
        $obj = $self->get_foe($arg) if ! $obj;
        if(! $obj)
        {
            $self->log("$arg is a wrong target"); 
            return 0;
        }
        $self->log(Dumper($obj->dump()));
    }
    elsif($answer eq 'SAVE')
    {
        if(! $arg)
        {
            $self->log("No file provided");
        }
        $self->write_all(lc($arg));
    }
    return 0;
}



sub add_player
{
    my $self = shift;
    my $name = shift;
    my $type = shift;
    my $template = shift;

    $template->{name} = $name;
    $template->{type} = $type;
   
    my $pl = Illuminated::Element::Stand::Player->new($template);
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
    my $name = shift;
    my $foe_package = shift;
    my $no_distance = shift;
    eval("require $foe_package");
    die $@ if $@;
    my $f = $foe_package->new($name);
    push @{$self->foes}, $f;
    unless($no_distance)
    {
        foreach(@{$self->players})
        {
            $self->set_distance($_, $f, 'none');
        }
    }
    return $f;
}

sub add_other
{
    my $self = shift;
    my $name = shift;
    my $other_package = shift;
    my $no_distance = shift;
    my $f = undef;
    if(ref($name) =~ /^Illuminated::Element/)
    {
        $f = $name;
    }
    else
    {
        eval("require $other_package");
        die $@ if $@;
        $f = $other_package->new($name);
    }
    push @{$self->others}, $f;
    unless($no_distance)
    {
        foreach(@{$self->players})
        {
            $self->set_distance($_, $f, 'none');
        }
    }
    return $f;
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
       return $self->foes->[$self->game_rand('get random foe', $self->foes)]; 
    }
    return undef;
}
sub get_other
{
    my $self = shift;
    my $name = shift;
    if($name)
    {
        my $tag = 'X-' . lc($name);
        for(@{$self->others})
        {
            return $_ if $_->tag eq $tag;
        }
    }
    return undef;
}
sub get_any
{
    my $self = shift;
    my $name = shift;
    my $command = shift;
    my $f = $self->get_foe($name);
    if($f)
    {
        if($f->suitable($self, $command))
        {
            return $f;
        }
    }
    my $o = $self->get_other($name);
    {
        if($o)
        {
            if($o->suitable($self, $command))
            {
                return $o;
            }
        }
    }
    return undef;
}
sub get_from_tag
{
    my $self = shift;
    my $tag = shift;
    if($tag =~ /^(.)-(.*)$/)
    {
        my $what = $1;
        my $who = $2;
        if($what eq 'P')
        {
            return $self->get_player($who)
        }
        else
        {
            return $self->get_any($who);
        }
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
    if($a->game_type eq 'player' )
    {
        $player = $a;
        if($b)
        {
            if(ref($b))
            {
                $foe = $b;
            }
            else
            {
                $foe = $self->get_any($b);
            }
        }
    }
    else#if($a->game_type eq 'foe') #come good for others too
    {
        $foe = $a;
        if($b)
        {
            if(ref($b))
            {
                $player = $b;
            }
            else
            {
                $player = $self->get_player($b);
            }
        }
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
    my $on_grid = shift;
    if($self->on_ground($a) && $self->on_ground($a)->tag eq $b->tag)
    {
        return 'on surface';
    }
    my ($player, $foe) = $self->detect_player_foe($a, $b);
    if($on_grid)
    {
        return $self->distance_matrix->{$player->tag}->{$foe->tag}
    }
    if( ($self->on_ground($player) && $self->on_ground($foe) && $self->on_ground($player)->tag eq $self->on_ground($foe)->tag) || #On the same ground
        ( ! $self->on_ground($player) && ! $self->on_ground($foe)) ) #Both in space
    {
        return $self->distance_matrix->{$player->tag}->{$foe->tag}
    }
    elsif( $self->on_ground($player) && $self->on_ground($foe) && $self->on_ground($player) ne $self->on_ground($foe)) #On different grounds
    {
        return 'none'
    }
    elsif(  $self->on_ground($player) && ! $self->on_ground($foe))
    {
        if($a->tag eq $player->tag)
        {
            return 'below';
        }
        else
        {
            return 'above';
        }
    }
    elsif( ! $self->on_ground($player) && $self->on_ground($foe))
    {
        if($a->tag eq $player->tag)
        {
            return 'above';
        }
        else
        {
            return 'below';
        }
    }
}
sub on_ground
{
    my $self = shift;
    my $a = shift;
    if(exists $self->ground_position->{$a->tag})
    {
        return $self->ground_position->{$a->tag}
    }
    else
    {
        return undef;
    }
}
sub set_ground
{
    my $self = shift;
    my $a = shift;
    my $where = shift; #undef is space
    $self->ground_position->{$a->tag} = $where;
}



sub set_far_from_all
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
        @select = (@{$self->foes}, @{$self->others});
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
            my $pick = $out[$self->game_rand( 'get target at distance', \@out )];
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
    if($s->game_type eq 'foe')
    {
        @{$self->foes} = grep { $_->tag ne $s->tag}  @{$self->foes};
    }
    elsif($s->game_type eq 'player')
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

sub execute_foe
{
    my $self = shift;
    my $foe = shift;
    my $command = shift;
    my $target = shift;
    
    if($target)
    {
        $self->log('[IA] ' . $foe->name . ": $command " . $target->name);
    }
    else
    {
        $self->log('[IA] ' . $foe->name . ": $command");
    }

    my $data = undef;
    if($command eq 'warn')
    {
        my @unw = $self->unaware_foe();
        my $f = $unw[$self->game_rand('aware command', \@unw)];
        $self->log($foe->name . " reaches " . $f->name . " and makes him aware!");
        $f->aware(1);
        $self->set_far_from_all($f);
    }
    elsif($command eq 'away')
    {
        $self->log($foe->name . " steps away from " . $target->name . "!");
        $data = {
            subject_1 => $foe,
            subject_2 => $target,
            direction => 'farther',
            try_type => undef,
            command => 'fly_away',
            call => 'play_move',
        };
    }
    elsif($command eq 'attack')
    {
        my ( $w ) = $foe->get_weapons_by_range($self->get_distance($foe, $target));
        $self->log($foe->name . " deals " . $w->damage . " damage to " . $target->name . " using " . $w->name . "!");
        $data = {
             subject_1 => $foe,
             subject_2 => $target,
             try_type => undef,
             command => 'attack',
             weapon => $w,
             damage => $w->damage,
             call => 'play_harm',
        };
    }
    elsif($command eq 'pursuit')
    {
        if($self->get_distance($foe, $target) eq 'above')
        {
            #Foes can always land on grounds, no need to get near
            $self->log($foe->name . ": pursuit from above (landing)");
            $data = {
                subject_1 => $foe,
                location => $self->on_ground($target),
                try_type => undef,
                command => 'land',
                call => 'play_land',
            };
        }
        elsif($self->get_distance($foe, $target) eq 'below')
        {
            #Foes can always land on grounds, no need to get near
            $self->log($foe->name . ": pursuit from below (lifting)");
            $data = {
                subject_1 => $foe,
                try_type => undef,
                command => 'lift',
                call => 'play_lift',
            };
        }
        else
        {
            $self->log($foe->name . " flyes to the " . $target->name . "!");
            $data = {
                subject_1 => $foe,
                subject_2 => $target,
                direction => 'closer',
                try_type => undef,
                command => 'fly_closer',
                call => 'play_move',
            };
        }
    }
    elsif($command eq 'parry')
    {
        $self->log($foe->name . " raises the shield");
        my $shield = $foe->get_weapon_by_type('shield');
        $data = {
             subject_1 => $foe,
             subject_2 => undef,
             try_type => undef,
             command => 'parry',
             weapon => $shield,
             damage => undef,
             call => undef,
        };
    }
    elsif($command =~ /device (.*)$/)
    {
        my $dev_name = $1;
        my $d = $foe->get_device($dev_name);
        $self->log($foe->name . " use device: $dev_name");
        $data = {
             subject_1 => $foe,
             subject_2 => $target,
             try_type => undef,
             device => $d,
             command => 'device',
             call => 'play_device',
        };
    }
    else
    {
        $self->log($foe->name . ": command is " . $command);
    }
    if($data)
    {
        $self->play_command($data);
    }

}
sub assign_action_point
{
    my $self = shift;
    my $who = shift;
    my @foes;
    if(! $who)
    {
        @foes = ( undef );
    }
    elsif(! ref($who) eq 'ARRAY')
    {
        @foes = ( $who );
    }
    else
    {
        @foes = @{$who};
    }

    foreach my $foe (@foes)
    {
        if($foe && $foe->game_type ne 'foe')
        {
            $self->log($foe->name . " not a foe");
            $foe = undef;
        }
        if(! $foe || ! $foe->active)
        {
            $self->log("Action point assigned random");
            $foe = $self->foes->[$self->game_rand('assigning action point', $self->foes)];
        }
        if($foe)
        {
            $self->log("Action point assigned to " . $foe->name);
            $foe->action_points($foe->action_points + 1);
        }
    }   
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

    my @targets = @{$data->{targets}};

    my %already = ();

    my @triggering = (@targets, $data->{weapon}, $data->{subject_1});
    foreach my $t (@triggering)
    {
        if($t)
        {
            $t->calculate_effects($self, $event, $data);
            $already{$t->tag} = 1 unless (ref($t) =~ /^Illuminated::Weapon/);
        }
    }
    my @others = ();
    my @first_group = ();
    my @second_group = ();
    if($data->{subject_1}->game_type eq 'player')
    {
        @first_group = @{$self->foes};
        @second_group = @{$self->players};
    }
    elsif($data->{subject_1}->game_type eq 'foe') 
    {
        @first_group = @{$self->players};
        @second_group = @{$self->foes};
    }
    foreach my $a (@first_group, @second_group)
    {
        if(! defined $already{$a->tag})
        {
            $a->calculate_effects($self, $event, $data);
        }
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
    $self->turn($self->turn + 1);
    foreach my $p (@{$self->players})
    {
        $p->counters_clock($self);
    }
    foreach my $f (@{$self->foes})
    {
        $f->counters_clock($self);
    }
    $self->current_tile->execute_turn($self);
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
    $self->log('---');
    foreach my $o (@{$self->others})
    {
        $self->log($o->description . " <" . $self->get_distance($p, $o) . ">");
    }
    
    print "\n";
    return 0;
}

sub fly_closer
{
    my $self = shift;
    my $fname = shift;

    #Preconditions
    my $any = $self->get_any($fname, 'fly_closer');
    if(! $any) { $self->log("$fname doesn't exists or is it not suitable"); return 0 }

    #Data
    my $data = {
        subject_1 => $self->active_player,
        subject_2 => $any,
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
        $self->log($any->name . " now " . $self->get_distance($self->active_player, $any) . " for " . $self->active_player->name); 
    }
    elsif($outcome == 1)
    {
        $self->log("Successful approach with consequences");
        $self->log($any->name . " now " . $self->get_distance($self->active_player, $any) . " for " . $self->active_player->name);
    }
    elsif($outcome == 0)
    {
        $self->log("Failed to approach!");
    }
    $self->assign_action_point($data->{reaction});
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
        my $f = $self->get_any($who, 'fly_away');
        if(! $f) { $self->log("$who doesn't exists or is not suitable"); return 0 }
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
        }
    }
    elsif($outcome == 0)
    {
        $self->log("Failed to escape! (some enemies gain an action point");
        foreach my $f ( @targets )
        {
            my $d = $self->get_distance($self->active_player, $f);
        }
    }
    $self->assign_action_point($data->{reaction});
    return 1;
}

sub land
{
    my $self = shift;
    my $where = shift;


    #Preconditions
    if(! $where) { $self->log("No where"); return 0 }
    my $place = $self->get_other($where);
    if(! $place) { $self->log("$where doesn't exists"); return 0 }
    if(! $place->ground) { $self->log("$where is not suitable for landing"); return 0 }
    if($self->get_distance($self->active_player, $place) ne 'near') { $self->log("Impossible to land on $where. Distance is " . $self->get_distance($self->active_player, $place)); return 0 }

    #Data
    my $data = {
        subject_1 => $self->active_player,
        location => $place,
        try_type => 'speed',
        command => 'land',
        call => 'play_land',
    };

    #Announcement
    $self->log("Landing on $where");
    
    #Action
    my $outcome = $self->play_command($data);
    if($outcome == 2)
    {
        $self->log("Successfully landed on $where!");
    }
    elsif($outcome == 1)
    {
        $self->log("Landed on $where with consequences!");
    }
    elsif($outcome == 0)
    {
        $self->log("Failed to land on $where!");
    }
    $self->assign_action_point($data->{reaction});
    return 1;    
}

sub lift
{
    my $self = shift;

    #Preconditions
    my $where = $self->on_ground($self->active_player);
    if(! $where) { $self->log("Player not on the ground"); return 0 }

    $where = $where->name;
    
    #Data
    my $data = {
        subject_1 => $self->active_player,
        try_type => 'power',
        command => 'lift',
        call => 'play_lift',
    };

    #Announcement
    $self->log("Lifting from $where");

    #Action
    my $outcome = $self->play_command($data);
    if($outcome == 2)
    {
        $self->log("Successfully lifted from $where!");
    }
    elsif($outcome == 1)
    {
        $self->log("Lifted from $where with consequences!");
    }
    elsif($outcome == 0)
    {
        $self->log("Failed to lift from $where!");
    }
    $self->assign_action_point($data->{reaction});
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
    }
    elsif($outcome == 0)
    {
        $self->log("Disengaging failed!");
    }
    $self->assign_action_point($data->{reaction});
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
        $foe = $self->get_any($fname, 'attack_foe');
        if(! $foe) { $self->log("$fname doesn't exists or is not suitable"); return 0 }
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
    }
    elsif($outcome == 0)
    {
        $self->log("Attack failed!");
    }
    $self->assign_action_point($data->{reaction});
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
    if(! $d->preconditions($self, $self->active_player)) { $self->log($d->name . " cannot be used"); return 0 }; 
    if(! $d->check_command($self, $self->active_player, $arg)) { $self->log("Bad command for " . $d->name); return 0 }; 

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
    #No need to assign reaction action points

    return 1;
}

sub cover
{
    my $self = shift;

    #Preconditions
    if(! $self->on_ground($self->active_player)) { $self->log("Player not on the ground"); return 0 }
    if(! $self->active_player->can_cover) { $self->log("Player can't cover"); return 0 }

    #Data
    my $data = {
        subject_1 => $self->active_player,
        try_type => undef,
        command => 'cover',
        call => 'play_cover',
    };

    #Action
    my $outcome = $self->play_command($data);
    if($outcome == 2)
    {
        $self->log($self->active_player->name . " gets cover");
    }
    else
    {
        #Can't fail
    }
    #No need to assign reaction action points
    return 1;    
}

# Commands support subs

sub play_command
{
    my $self = shift;
    my $data = shift;

    my @targets = (); #Useful on general purporse checks
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
    elsif($data->{command} eq 'device')
    {
        @targets = $data->{device}->get_targets($self, $data->{subject_1}, $data->{arg});
    }
    $data->{targets} = \@targets;

    my $throw = undef;
    if($data->{try_type})
    {
        my $try = $data->{try_type};
        $data->{dice_mods} = [];
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
        $outcome = 0; #failure
    }
    $data->{outcome} = $outcome;
    $data->{reaction} = [];
    $self->calculate_effects("before " . $data->{command}, $data);
    my $call = $data->{call};
    $self->$call($data) if $call;
    $self->calculate_effects("after " . $data->{command}, $data) unless $outcome == 0;
    return $outcome;
}

sub play_move
{
    my $self = shift;
    my $data = shift;

    my $just_one = 0;
    my @targets;

    if( ! (ref($data->{subject_2}) eq 'ARRAY') )
    {
        @targets = ( $data->{subject_2} );
    }
    else
    {
        @targets = @{$data->{subject_2}};
    }
    $just_one = ( int(@targets) == 1 );

    foreach my $f ( @targets )
    {
        my $d = $self->get_distance($data->{subject_1}, $f, 1);
        if( ( ($d eq 'close' || $d eq 'near') && $data->{direction} eq 'farther') ||
            ( ($d eq 'far'   || $d eq 'near') && $data->{direction} eq 'closer' )
          )
        { 
            if($data->{'outcome'} == 2)
            {
                $self->move($data->{subject_1}, $f, $data->{direction});
            }
            elsif($data->{'outcome'} == 1)
            {
                if($just_one)
                {
                    $self->move($data->{subject_1}, $f, $data->{direction});
                    push @{$data->{reaction}}, $f;
                }
                else
                {
                    my $throw = $self->dice(1);
                    if($throw >= 5)
                    {
                        $self->move($data->{subject_1}, $f, $data->{direction});
                    }
                    elsif($throw >= 3)
                    {
                        $self->move($data->{subject_1}, $f, $data->{direction});
                        push @{$data->{reaction}}, $f;
                    }
                    else
                    {
                        push @{$data->{reaction}}, $f;
                    }
                }
            }
            elsif($data->{'outcome'} == 0)
            {
                if($just_one)
                {
                    push @{$data->{reaction}}, $f;
                }
                else
                {
                    my $throw = $self->dice(1);
                    if($throw < 5)
                    {
                        push @{$data->{reaction}}, $f;
                    }
                }
            }
        }
    }
}

sub play_land
{
    my $self = shift;
    my $data = shift;

    if($data->{'outcome'} == 2)
    {
        $self->set_ground($data->{subject_1}, $data->{location});
    }
    elsif($data->{'outcome'} == 1)
    {
        $self->set_ground($data->{subject_1}, $data->{location});
        push @{$data->{reaction}}, undef;
    }
    elsif($data->{'outcome'} == 0)
    {
        push @{$data->{reaction}}, undef;
    }
}

sub play_lift
{
    my $self = shift;
    my $data = shift;

    if($data->{'outcome'} == 2)
    {
        $self->set_ground($data->{subject_1}, undef);
    }
    elsif($data->{'outcome'} == 1)
    {
        $self->set_ground($data->{subject_1}, undef);
        push @{$data->{reaction}}, undef;
    }
    elsif($data->{'outcome'} == 0)
    {
        push @{$data->{reaction}}, undef;
    }
}

sub play_harm
{
    my $self = shift;
    my $data = shift;
    if($data->{outcome} == 2)
    {
        $self->harm($data->{subject_1}, $data->{subject_2}, $data->{damage});
    }
    elsif($data->{outcome} == 1)
    {
        $self->harm($data->{subject_1}, $data->{subject_2}, $data->{damage});
        push @{$data->{reaction}}, $data->{subject_2};
    }
    elsif($data->{outcome} == 0)
    {
        push @{$data->{reaction}}, $data->{subject_2};
    }
}

sub play_device
{
    my $self = shift;
    my $data = shift;
    $self->device($data->{subject_1}, $data->{device}, $data->{arg});
}
sub play_cover
{
    my $self = shift;
    my $data = shift;
    $data->{subject_1}->get_cover();
}


sub dump
{
    my $self = shift;

    return {
        current_tile => ref($self->current_tile),
        active_player_counter => $self->active_player_counter,
        active_player_device_chance => $self->active_player_device_chance,
        turn => $self->turn
    }
}

1;
