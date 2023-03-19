package Illuminated::Role::Logger;

use strict;
use v5.10;
use Moo::Role;
use DateTime;

has log_prefix => (
    is => 'rw',
    default => 'illuminated'
);

has log_dir => (
    is => 'rw',
    default => 'log/'
);
    
has log_name => (
    is => 'rw',
    default => ""
);

has on_screen => (
    is => 'rw',
    default => 1
);

has on_file => (
    is => 'rw',
    default => 1
);
has on_memory => (
    is => 'rw',
    default => 1
);

has memory_log => (
    is => 'ro',
    default => sub { [] }
);
has memory_log_limit => (
    is => 'ro',
    default => 100
);


sub init_log
{
    my $self = shift;
    my $file = $self->log_dir . $self->log_prefix . '_' . DateTime->now->ymd('') . "_" . DateTime->now->hms('') . ".log";
    $self->log_name($file);
}

sub log
{
    my $self = shift;
    my $message = shift;
    if($self->on_screen)
    {
        say $message;
    }
    if($self->on_file)
    {
        open(my $fh, ">> " . $self->log_name) || die $!;
        print {$fh} "$message\n";
        close($fh);
    }
    if($self->on_memory)
    {
        push @{$self->memory_log}, $message;
        if(@{$self->memory_log} > $self->memory_log_limit)
        {
            shift @{$self->memory_log};
        }
        
    }
}

sub screen_only
{
    my $self = shift;
    my $message = shift;
    if($self->on_screen)
    {
        say $message;
    }
}

sub file_only
{
    my $self = shift;
    my $message = shift;
    open(my $fh, ">> " . $self->log_name) || die $!;
    print {$fh} "$message\n";
    close($fh);
}

sub find_log
{
    my $self = shift;
    my $message = shift;
    my $stop = shift;
    for(my $i = -1; $i > $self->memory_log_limit * -1; $i--)
    {
        my $log = $self->memory_log->[$i];
        chomp $log;
        last if($log eq $stop);
        return 1 if($log eq $message);
    }
    return 0;
}

1;

