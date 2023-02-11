package Illuminated::Role::Logger;

use strict;
use v5.10;
use Moo::Role;
use DateTime;
    
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


sub init_log
{
    my $self = shift;
    my $file = 'illuminated_' . DateTime->now->ymd('') . "_" . DateTime->now->hms('') . ".log";
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
}
1;

