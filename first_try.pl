#!/usr/bin/perl

use v5.21;
use Storable qw(dclone);

#SETUP

my $mecha = {
    health => 10,
    power => 3,
    speed => 2,
    mind => 1,
}; 
my $mecha2 = {
    health => 10,
    power => 1,
    speed => 1,
    mind => 3,
}; 

my %foe_mechas = (
    thug => {
        health => 2,
        type => 'thug'
    },
    gunner => {
        health => 2,
        type => 'gunner',
    }
);

my $players =
    { 
        "paladin" => dclone($mecha),
        "templar" => dclone($mecha2)
    };
$players->{"paladin"}->{active} = 1;
$players->{"templar"}->{active} = 1;

my @active_players = qw( paladin templar );

my @fnames = qw ( alpha beta gamma delta epsilon ro iota );
my @active_fnames = @{dclone(\@fnames)};
my $foes;

my $distance_matrix;

my %foe_type = (
    'alpha' => 'thug',
    'beta' => 'thug',
    'gamma' => 'thug',
    'delta' => 'thug',
    'epsilon' => 'thug',
    'ro' => 'gunner',
    'iota' => 'gunner',
);


foreach my $fname ( @fnames )
{
    $foes->{$fname} = dclone($foe_mechas{$foe_type{$fname}});
    $foes->{$fname}->{active} = 1;
    $foes->{$fname}->{aware} = 0;
    foreach my $p (@active_players)
    {
        $distance_matrix->{$p}->{$fname} = 'none';
    }
    $foes->{$fname}->{action_points} = 0;
}
my @aw_words = qw(unaware aware);
my $answer;


#MAIN LOOP

my $playing = undef;

foreach my $p (@active_players)
{
    while(! $answer)
    {
        $playing = $p;
        print "\n";
        say "ACTIVE PLAYER is $p";
        $answer = dialog('entering patrol')
    }
    say "You chose $answer";
    if($answer eq 'N')
    {
        say "No strategy chosen. I will throw a die for each foe";
        start_patrol('N');
    }
    elsif($answer eq 'S')
    {
        say "Stealth passage chosen. Rolling by intelligence about sneaking through enemy lines";
        start_patrol('S');
    }
    elsif($answer eq 'R')
    {
        say "Rush in chosen. Rolling by power about surprise attack on enemy patrol";
        start_patrol('R');
    }
    $answer = undef;
}

my $fighting = 1;
$answer = undef;
my $player_cursor = 0;
while($fighting)
{
    my $command_given = 0;
    $playing = $active_players[$player_cursor];
    while(! $answer)
    {
        print "\n";
        say "ACTIVE PLAYER is $playing";
        if(close_combat())
        {
            $answer = dialog('close combat')
        }
        else
        {
            $answer = dialog('combat')
        }
    }
    if($answer eq 'S')
    {
        situation();
    }
    elsif($answer =~ /^S (.*)$/)
    {
        situation(lc($1));
    }
    elsif($answer eq 'A')
    {
        my $res = attack_enemy();
        $command_given = 1 if ($res);
    }
    elsif($answer =~ /^A (.*)$/)
    {
        my $res = attack_enemy(lc($1));
        $command_given = 1 if ($res);
    }
    elsif($answer =~ /^C (.*)$/)
    {
        my $res = fly_closer(lc($1));
        $command_given = 1 if ($res);
    }
    elsif($answer =~ /^F (.*)$/)
    {
        my $res = fly_away(lc($1));
        $command_given = 1 if ($res);
    }
    elsif($answer eq 'D')
    {
        my $res = disengage();
        $command_given = 1 if ($res);
    }
    else
    {
        say "Bad command";
    }
    $answer = undef;
    if($command_given)
    {
        say "Consequences of your actions...";
        run_enemies();
        $player_cursor++;
        if($player_cursor > $#active_players)
        {
            $player_cursor = 0;
            say "End of turn management...";
            for(my $i = 0; $i < 1; $i++)
            {
                assign_action_point(undef);
            }
            run_enemies();
        }
    }
    if(! @active_players)
    {
        say "DEFEAT! Players destroyed!";
        $fighting = 0;
    }
    if(! @active_fnames)
    {
        say "VICTORY! All enemies have been destroyed!";
        $fighting = 0;
    }    

}

#SUBS

sub dialog
{
    my $d = shift;
    my $answer = undef;
    my @options = ();
    if($d eq 'entering patrol' && ! aware_present())
    {
        @options = qw( N S R );
        say "Entering enemy patrol zone";
        say "[N]o strategy";
        say "[S]tealth passage (mind try)";
        say "[R]ush in (power try)";
        print "Choose: ";
    }
    elsif($d eq 'entering patrol' && aware_present())
    {
        @options = qw( N R );
        say "Entering enemy patrol zone (enemy units already alerted)";
        say "[N]o strategy";
        say "[R]ush in (power try)";
        print "Choose: ";
    }
    elsif($d eq 'combat')
    {
        @options = qw( S C F A );
        say "Combat turn";
        say "[S]how current situation";
        say "[C]lose on enemy (speed try)";
        say "[F]ly away from enemies (speed try)";
        say "[A]ttack enemy (mind try)";
    }
    elsif($d eq 'close combat')
    {
        @options = qw( S D A );
        say "Combat turn (close combat)";
        say "[S]how current situation";
        say "[D]isengage";
        say "[A]ttack enemy (power try)";
    }
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

sub dice
{
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

sub start_patrol
{
    my $command = shift;
    if($command eq 'N')
    {
        foreach my $fname ( @active_fnames )
        {
            setup_enemy($fname);
        }
    }
    elsif($command eq 'S')
    {
        my $throw = dice($players->{$playing}->{mind});
        if($throw >= 5)
        {
            say "PASSED UNDETECTED!";
        }
        elsif($throw >= 3)
        {
            say "Same result of no strategy";
            start_patrol('N')
        }
        else
        {
            say "All enemies aware! A turn to the enemy!";
            foreach my $fname ( @active_fnames )
            {
                setup_enemy($fname, undef, 1);
            }
        }
    }
    elsif($command eq 'R')
    {
        my $throw = dice($players->{$playing}->{power});
        if($throw >= 5)
        {
            say "Enemy killed by surprise! Close to a second enemy. All enemies aware!";
            my $killed = kill_enemy();
            my $who = $active_fnames[rand @active_fnames];
            $distance_matrix->{$playing}->{$who} = 'close';
            $foes->{$who}->{aware} = 1;
            say "$who aware and close";
            foreach my $fname ( @active_fnames )
            {
                if($fname ne $who)
                {
                    setup_enemy($fname, undef, 1);
                }
            }
        }
        elsif($throw >= 3)
        {
            say "Close to an enemy! All enemies aware!";
            my $who = $active_fnames[rand @active_fnames];
            $distance_matrix->{$playing}->{$who} = 'close';
            $foes->{$who}->{aware} = 1;
            say "$who aware and close";
            foreach my $fname ( @active_fnames )
            {
                if($fname ne $who)
                {
                    setup_enemy($fname, undef, 1);
                }
            }
        }
        else
        {
            say "All enemies aware!";
            { 
                foreach my $fname ( @active_fnames )
                {
                    setup_enemy($fname, undef, 1);
                }
            }
        }
    }
}

sub setup_enemy
{
    my $fname = shift;
    my $distance = shift;
    my $awareness = shift;
    my $throw = dice(1, 1);

    my $a;
    my $d;
    if($throw >= 5)
    {
        $a = $awareness ? $awareness : 0;
        $d = $distance ? $distance : 'far'; #Used only if enemy already aware
    }
    elsif($throw >= 3)
    {
        $a = $awareness ? $awareness : 1;
        $d = $distance ? $distance : 'far';
    }
    else
    {
        $a = $awareness ? $awareness : 1;
        $d = $distance ? $distance : 'near';
    }
    $foes->{$fname}->{aware} = $a if ! $foes->{$fname}->{aware};
    foreach my $p ( @active_players )
    {
        if($p eq $playing)
        {
            $distance_matrix->{$p}->{$fname} = $d if $foes->{$fname}->{aware};
        }
        else
        {
            if($distance_matrix->{$p}->{$fname} eq 'none' && $foes->{$fname}->{aware})
            {
                $distance_matrix->{$p}->{$fname} = 'far';
            }
        }
    }

    if($a)
    {
        say "$fname aware and $d";
    }
    else
    {
        say "$fname unaware of you";
    }
}

sub situation
{
    my $who = shift || $playing;
    print "\n";
    say "$who: HEALTH " . $players->{$who}->{health};
    print "\n";
    foreach my $fname ( @active_fnames )
    {
        say "$fname (" .  $foes->{$fname}->{type} . "): HEALTH " . $foes->{$fname}->{health} . " " . 
            join(" ", $aw_words[ $foes->{$fname}->{aware} ], $distance_matrix->{$who}->{$fname});    
    }
    print "\n";
}



sub attack_enemy
{
    my $fname = shift;
    if(close_combat())
    {
        if(! $fname)
        {
            $fname = close_combat();
        }
        if($fname ne close_combat()) { say "Enemy close. You can't attack others"; return 0 };
    } 
    if(! $fname) { say "No enemy given"; return 0 };
    if( ! exists $foes->{$fname} ){ say "$fname doesn't exists"; return 0 }; 
    if( ! $foes->{$fname}->{active} ){ say "$fname is not active"; return 0 };
    if( $distance_matrix->{$playing}->{$fname} eq 'far' || $distance_matrix->{$playing}->{$fname} eq 'none' ){ say "$fname is far"; return 0 };
    my $try;
    my $damage;
    if( $distance_matrix->{$playing}->{$fname} eq 'near')
    {
        say "Attacking $fname with gun (mind try)";
        $try = $players->{$playing}->{mind};
        $damage = 1;
    }
    elsif( $distance_matrix->{$playing}->{$fname} eq 'close')
    {
        say "Attacking $fname with sword (power try)";
        $try = $players->{$playing}->{power};
        $damage = 2;
    }
    my $throw = dice($try);
    if($throw >= 5)
    {
        say "Successful attack!";
        harm_enemy($fname, $damage);
    }
    elsif($throw >= 3)
    {
        say "Successful attack with consequences!";
        harm_enemy($fname, $damage);
        assign_action_point($fname);
    }
    else
    {
        say "Attack failed!";
        assign_action_point($fname);
    }
    return 1;
}

sub fly_closer
{
    my $fname = shift;
    if( ! exists $foes->{$fname}                          ) { say "$fname doesn't exists";          return 0 }; 
    if( ! $foes->{$fname}->{active}                       ) { say "$fname is not active";           return 0 };
    if( $distance_matrix->{$playing}->{$fname} eq 'close' ) { say "$fname already close";           return 0 };
    if( my $cl = f_distance($fname, 'close')              ) { say "$cl is already close to $fname"; return 0 }; 
    say "Flying closer to $fname (speed try)";
    my $throw = dice($players->{$playing}->{speed});
    if($throw >= 5)
    {
        say "Successfull approach";
        move($playing, 'closer', $fname);
    }
    elsif($throw >= 3)
    {
        say "Successfull approach with consequences";
        move($playing, 'closer', $fname);
        assign_action_point($fname);
    }
    else
    {
        say "Failed to approach!";
        assign_action_point($fname);
    }
    return 1;
}

sub fly_away
{
    my $who = shift;
    my @targets;
    if($who eq '_all')
    {
        if(! someone_near()) { say "Nobody is near"; return 0 }
        say "Flying away from all enemies (speed try)";
        @targets = ( @active_fnames );
    }
    else
    {
        if($distance_matrix->{$playing}->{$who} ne 'near') { say "$who is not near"; return 0 }
        say "Flying away from $who (speed try)";
        @targets = ( $who );
    }
    my $throw = dice($players->{$playing}->{speed});
    if($throw >= 5)
    {
        say "Successfully escaped!";
        foreach my $fname ( @targets )
        {
            move($playing, 'farther', $fname);
        }
    }
    elsif($throw >= 3)
    {
        say "Uncomplete escape! Rolling enemies one by one";
        foreach my $fname ( @targets )
        {
            if($distance_matrix->{$playing}->{$fname} ne 'far' &&
               $distance_matrix->{$playing}->{$fname} ne 'none' )
            { 
                my $throw = dice(1);
                if($throw >= 5)
                {
                    move($playing, 'farther', $fname);
                }
                elsif($throw >= 3)
                {
                    say "$fname still " . $distance_matrix->{$playing}->{$fname};
                }
                else
                {
                    say "$fname still " . $distance_matrix->{$playing}->{$fname} . " with consequences";
                    assign_action_point($fname);
                }
            }
        }
    }
    else
    {
        say "Failed to escape!";
        foreach my $fname ( @targets )
        {
            if($distance_matrix->{$playing}->{$fname} ne 'far' &&
               $distance_matrix->{$playing}->{$fname} ne 'none' )
            { 
                assign_action_point($fname);
            }
        }
    }
    return 1;
}

sub disengage
{
    my $fname = close_combat();
    if(! $fname) { say "No need to disengage"; return 0 };
    say "Disengaging from $fname (power try)";
    my $throw = dice($players->{$playing}->{power});
    if($throw >= 5)
    {
        say "Successfully disengaged!";
        move($playing, 'farther', $fname);
    }
    elsif($throw >= 3)
    {
        say "Disengaged with consequences";
        move($playing, 'farther', $fname);
        assign_action_point($fname);
    }
    else
    {
        say "Disengaging failed!";
        assign_action_point($fname);
    }
    return 1;
}


sub harm_enemy
{
    my $fname = shift;
    my $damage = shift;
    $foes->{$fname}->{health} = $foes->{$fname}->{health} - $damage;
    say "$fname gets $damage dameges";
    if($foes->{$fname}->{health} <= 0)
    {
        kill_enemy($fname);
    }
}

sub kill_enemy
{
    my $who = shift;

    $who = $active_fnames[rand @active_fnames] if ! $who;
    $foes->{$who}->{active} = 0;
    say "$who killed!";
    @active_fnames = grep { $_ ne $who} @active_fnames;
    return $who;
}

sub assign_action_point
{
    my $preferred = shift;
    if($preferred &&
       $foes->{$preferred}->{active}) #An enemy can have more than one action point
    {
        $foes->{$preferred}->{action_points} = $foes->{$preferred}->{action_points} + 1;
        say "Action point given to $preferred!";
    }
    else
    {
        my $fname = $active_fnames[rand @active_fnames];
        if($foes->{$fname}->{aware})
        {
            $foes->{$fname}->{action_points} = $foes->{$fname}->{action_points} + 1;
            say "Action point given to $fname!";
        }
        else
        {
            say "Action point given to $fname but unaware! Action point destroyed";
        }
    }
}

sub run_enemies
{
    my $enough = 0;

    while(! $enough)
    {
        $enough = 1;
        foreach my $fname ( @active_fnames )
        {
            if($foes->{$fname}->{action_points} > 0)
            {
                $foes->{$fname}->{action_points} = $foes->{$fname}->{action_points} -1;
                ia($fname);
                $enough = 0;    
            }
        }
    }
}

sub ia
{
    my $fname = shift;
    my $command = undef;
    my $target = undef;
    if(unaware_present())
    {
        my $throw = dice(1, 1);
        $command = 'warn' if($throw < 3);
    }
    if(! $command)
    {
        my %c;
        if($foes->{$fname}->{type} eq 'thug')
        {
            %c = ( 'close' => 'away',
                   'near'  => 'attack',
                   'far'   => 'pursuit' );
        }
        elsif($foes->{$fname}->{type} eq 'gunner')
        {
            %c = ( 'close' => 'away',
                   'near'  => 'away',
                   'far'   => 'attack' );
        }
        foreach my $distance (qw(close near far))
        {
            my $p = f_distance($fname, $distance);
            if($p)
            {
                $command = $c{$distance};
                $target = $p;
                last;
            }
        }
    }
    if($command eq 'warn')
    {
        my $other = unaware_present();
        say "$fname reaches $other and makes him aware!";
        $foes->{$other}->{aware} = 1;
        foreach my $p (@active_players)
        {
            $distance_matrix->{$p}->{$other} = 'far';
        }
    }
    elsif($command eq 'away')
    {
        say "$fname steps away from $target!";
        move($target, 'farther', $fname);
    }
    elsif($command eq 'attack')
    {
        say "$fname deals 1 damage to $target!";
        harm_player($target, 1);
    }
    elsif($command eq 'pursuit')
    {
        say "$fname flyes to the $target!";
        move($target, 'closer', $fname);
    }
}

sub harm_player
{
    my $target = shift;
    my $damage = shift;
    $players->{$target}->{health} = $players->{$target}->{health} - 1;
    say "$target receives $damage damages. $target" . "'s health is now " . $players->{$target}->{health};
    if($players->{$target}->{health} <= 0)
    {
        say "$target killed!";
        @active_players = grep { $_ ne $target } @active_players;
    }
}

sub move
{
    my $player = shift;
    my $direction = shift;
    my $fname = shift;
    return 0 if $distance_matrix->{$player}->{$fname} eq 'none';
    if($direction eq 'closer')
    {
        if($distance_matrix->{$player}->{$fname} eq 'far')
        {
            $distance_matrix->{$player}->{$fname} = 'near';  
            say "$fname is now near to $player";
        }
        elsif($distance_matrix->{$player}->{$fname} eq 'near')
        {
            $distance_matrix->{$player}->{$fname} = 'close';  
            say "$fname is now close to $player";
        }    
        else
        {
            #say "Impossible movement";
            return 0;
        }
    }
    elsif($direction eq 'farther')
    {
        if($distance_matrix->{$player}->{$fname} eq 'near')
        {
            $distance_matrix->{$player}->{$fname} = 'far';  
            say "$fname is now far from $player";
        }
        elsif($distance_matrix->{$player}->{$fname} eq 'close')
        {
            $distance_matrix->{$player}->{$fname} = 'near';  
            say "$fname is now near to $player";
        }    
        else
        {
            #say "Impossible movement";
            return 0;
        }
    }
    return 1;
}


#BOOLEANS

sub close_combat
{
    foreach my $fname ( @active_fnames )
    {
        return $fname if($distance_matrix->{$playing}->{$fname} eq 'close')
    }
    return undef;
}

sub unaware_present
{
    foreach my $fname ( @active_fnames )
    {
        return $fname if ! $foes->{$fname}->{aware};
    }
    return undef;
}
sub aware_present
{
    foreach my $fname ( @active_fnames )
    {
        return $fname if $foes->{$fname}->{aware};
    }
    return undef;
}

sub someone_near
{
    foreach my $fname ( @active_fnames )
    {
        return $fname if($distance_matrix->{$playing}->{$fname} eq 'close' || $distance_matrix->{$playing}->{$fname} eq 'near')
    }
    return undef;
}

sub f_distance
{
    my $fname = shift;
    my $distance = shift;
    my $player = shift;
    if($player)
    {
        return $player if($distance_matrix->{$player}->{$fname} eq $distance) 
    }
    else
    {
        my @urn = ();
        foreach my $p (@active_players)
        {
            push @urn, $p if($distance_matrix->{$p}->{$fname} eq $distance)
        }   
        if(@urn)
        {
            return $urn[rand @urn]
        }
        else
        {
            undef;
        }
    }
}

