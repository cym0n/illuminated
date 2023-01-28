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

my $sentry = {
    health => 2
};

my $players =
    { 
        "Paladin" => dclone($mecha)
    };
$players->{"Paladin"}->{active} = 1;

my @fnames = qw ( alpha beta gamma delta epsilon ro iota );
my @active_fnames = @{dclone(\@fnames)};
my $foes;

my $distance_matrix;

foreach my $fname ( @fnames )
{
    $foes->{$fname} = dclone($sentry);
    $foes->{$fname}->{active} = 1;
    $foes->{$fname}->{aware} = 0;
    $distance_matrix->{"Paladin"}->{$fname} = 'none';
}
my @aw_words = qw(unaware aware);
my $answer;


#MAIN LOOP

while(! $answer)
{
    print "\n";
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

my $fighting = 1;
$answer = undef;
while($fighting)
{
    while(! $answer)
    {
        print "\n";
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
}





#SUBS

sub dialog
{
    my $d = shift;
    my $answer = undef;
    my @options = ();
    if($d eq 'entering patrol')
    {
        @options = qw( N S R );
        say "Entering enemy patrol zone";
        say "[N]o strategy";
        say "[S]tealth passage (mind try)";
        say "[R]ush in (power try)";
        print "Choose: ";
    }
    elsif($d eq 'combat')
    {
        @options = qw( S C F A );
        say "Combat turn";
        say "[S]how current situation";
        say "[C]lose on enemy";
        say "[F]ly away from enemies";
        say "[A]ttack enemy";
    }
    elsif($d eq 'close combat')
    {
        @options = qw( S D A );
        say "Combat turn (close combat)";
        say "[S]how current situation";
        say "[D]isengage";
        say "[A]ttack enemy";
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
        my $throw = dice($players->{'Paladin'}->{mind});
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
        my $throw = dice($players->{'Paladin'}->{power});
        if($throw >= 5)
        {
            say "Enemy killed by surprise! Close to a second enemy. All enemies aware!";
            my $killed = kill_enemy();
            say "$killed killed";
            my $who = $active_fnames[rand @active_fnames];
            $distance_matrix->{"Paladin"}->{$who} = 'close';
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
            $distance_matrix->{"Paladin"}->{$who} = 'close';
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
        $d = $distance ? $distance : 'far';
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
    $foes->{$fname}->{aware} = $a;
    $distance_matrix->{"Paladin"}->{$fname} = $d if $a;

    if($a)
    {
        say "$fname aware and $d";
    }
    else
    {
        say "$fname unaware of you";
    }
}

sub kill_enemy
{
    my $who = shift;

    $who = $active_fnames[rand @active_fnames] if ! $who;
    $foes->{$who}->{active} = 0;
    @active_fnames = grep { $_ ne $who} @active_fnames;
    return $who;
}

sub situation
{
    print "\n";
    say "Paladin: HEALTH " . $players->{"Paladin"}->{health};
    print "\n";
    foreach my $fname ( @active_fnames )
    {
        say "$fname: HEALTH " . $foes->{$fname}->{health} . " " . 
            join(" ", $aw_words[ $foes->{$fname}->{aware} ], $distance_matrix->{"Paladin"}->{$fname});    
    }
    print "\n";
}

sub close_combat
{
    foreach my $fname ( @active_fnames )
    {
        return $fname if($distance_matrix->{"Paladin"}->{$fname} eq 'close')
    }
    return 0;
}
