package Illuminated::Role::Tester;

use strict;
use v5.10;

use Moo::Role;

use Illuminated::Weapon::Balthazar;
use Illuminated::Weapon::Caliban;
use Illuminated::Weapon::Gospel;
use Illuminated::Device::Jammer;
use Illuminated::Device::SwarmGun;
use Illuminated::Device::CoriolisThruster;
use Illuminated::Device::FleuretThruster;

requires 'log';
requires 'running';
requires 'loaded_dice';
requires 'loaded_dice_counter';
requires 'auto_commands';
requires 'auto_commands_counter';
requires 'fake_random';
requires 'fake_random_counter';

sub init_test
{
    my $package = shift;
    my $tile = shift;
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
    $game->one_tile($tile);
    return $game;
}

sub load_test
{
    my $package = shift;
    my $file = shift;
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
    $game->load($file);
    return $game;
}

sub init_ia
{
    my $package = shift;
    my $game_start = shift;
    my $ia_string = shift;
    my $counter = shift;
    my @chunks = ( $ia_string =~ m/../g );
    my @commands = ('N', 'N');
    for(@chunks)
    {
        push @commands, '@' . $_;
    }
    my $game = Illuminated::Game->new(
        {   auto_commands => \@commands,
            ia_players => 1,
            log_prefix => 'ia' . $counter,
            on_screen => 0,
        }
    );
    $game->$game_start;
    $game->log("IA STRING: $ia_string");
    return $game;
}

sub configure_scenario
{
    my $self = shift;
    my $loaded_dice = shift;
    my $fake_random = shift;
    my $auto_commands = shift;
    my $title = shift;
    $self->loaded_dice($loaded_dice);
    $self->loaded_dice_counter(0);
    $self->auto_commands($auto_commands);
    $self->auto_commands_counter(0);
    $self->fake_random($fake_random);
    $self->fake_random_counter(0);
    if($title)
    {
        $self->log("\n##### $title #####")
    }
    else
    {
        $self->log("\n");
    }
    $self->running(1);
}

sub one_tile
{
    my $self = shift;
    my $tile = shift;
    eval("require $tile");
    die $@ if $@;
    my $tile_obj = $tile->new;
    $self->init_log;
    my $player;
    $player = $self->add_player('Paladin', 'Maverick', $self->player_templates->{'Maverick'});
    $player->add_weapon(Illuminated::Weapon::Balthazar->new());
    $player->add_weapon(Illuminated::Weapon::Caliban->new());
    $player->add_device(Illuminated::Device::Jammer->new());
    $player->add_device(Illuminated::Device::FleuretThruster->new());
    $player = $self->add_player('Templar', 'Tesla', $self->player_templates->{'Tesla'});
    $player->add_weapon(Illuminated::Weapon::Balthazar->new());
    $player->add_weapon(Illuminated::Weapon::Caliban->new());
    #$player->add_weapon(Illuminated::Weapon::Gospel->new());
    $player->add_device(Illuminated::Device::SwarmGun->new());
    $player->add_device(Illuminated::Device::CoriolisThruster->new());
    $self->current_tile($tile_obj);
}

1;
