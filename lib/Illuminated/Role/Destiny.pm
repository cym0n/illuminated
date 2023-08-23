package Illuminated::Role::Destiny;

use strict;
use v5.10;
use Moo::Role;

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

requires 'log';
requires 'file_only';

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
    }
    foreach my $m (@{$mods})
    {
        if($m eq '1max -1')
        {
            @throws = sort @throws;
            $throws[-1] = $throws[-1] -1;
        }
    }
    for(@throws) { $result = $_ if($result < $_) }

    #$result = $throw if($throw > $result);
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

sub game_rand
{
    my $self = shift;
    my $reason = shift;
    my $seed = shift;;
    my $number = undef;
    if(ref($seed) eq 'ARRAY')
    {
        $number = @{$seed};
    }
    else
    {
        $number = $seed;
    }

    $self->file_only("Random evoked, range $number, reason $reason");
    if(exists $self->fake_random->[$self->fake_random_counter])
    {
        my $value = $self->fake_random->[$self->fake_random_counter];
        if($value > $number+1)
        {
            die("Failing tampering random. $value > $number. Counter is: ". $self->fake_random_counter);
        }
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

1;
