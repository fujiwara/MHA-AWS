package MHA::AWS;

use 5.008001;
use strict;
use warnings;
use Log::Minimal;
use AWS::CLIWrapper;
use Time::HiRes qw/ sleep /;
use Scalar::Util qw/ blessed /;
use Moo;

our $FAILOVER_TIMEOUT = 60;
our $CHECK_INTERVAL   = 3;
our $VERSION          = "0.01";

has orig_master_host             => ( is => "rw" );
has new_master_host              => ( is => "rw" );
has attachment_id                => ( is => "rw" );
has interface_id                 => ( is => "rw" );
has current_attached_instance_id => ( is => "rw" );
has vip                          => ( is => "rw" );
has instance_ids                 => ( is => "rw", default => sub { +{} } );
has interface_name => (
    is       => "rw",
    required => 1,
);
has aws => (
    is      => "rw",
    default => sub {
        AWS::CLIWrapper->new();
    },
);

sub init {
    my $self = shift;

    my $res;
    $res = $self->ec2("describe-network-interfaces");
    my ($interface) = grep {
        $_->{Description} eq $self->interface_name
    } @{ $res->{NetworkInterfaces} };
    unless ($interface) {
        critf "Can't find network interface: %s", $self->interface_name;
        die;
    }

    $self->attachment_id( $interface->{Attachment}->{AttachmentId} );
    $self->interface_id( $interface->{NetworkInterfaceId} );
    $self->current_attached_instance_id( $interface->{Attachment}->{InstanceId} );
    $self->vip( $interface->{PrivateIpAddress} );

    # tag から hostname => instance-id の対応表を作る
    $res = $self->ec2("describe-tags");
    for my $tag (@{ $res->{Tags} }) {
        if ($tag->{ResourceType} eq "instance" && $tag->{Key} eq "Name") {
            $self->instance_ids->{ $tag->{Value} } = $tag->{ResourceId};
        }
    }

    if ( $self->new_master_host && !$self->new_master_instance_id ) {
        critf "Can't detect new_master_instance_id. abort";
        die;
    }
    if ( $self->orig_master_host && !$self->orig_master_instance_id ) {
        critf "Can't detect orig_master_instance_id. abort";
        die;
    }
}

sub ec2 {
    my $self = shift;
    my ($command, $args) = @_;
    infof "aws ec2 %s %s", $command, defined($args) ? ddf $args : "";
    my $res = $self->aws->ec2($command, $args);
    if ($res) {
        debugf "result: %s", ddf $res;
    }
    else {
        critf "failed";
        die;
    }
    $res;
}

sub ping {
    my $self    = shift;
    my $ip_addr = shift;
    system(qw/ timeout 3 ping -c 1 -t 3 /, $ip_addr) == 0 ? 1 : 0;
}

sub new_master_instance_id {
    my $self = shift;
    $self->instance_ids->{ $self->new_master_host };
}

sub orig_master_instance_id {
    my $self = shift;
    $self->instance_ids->{ $self->orig_master_host };
}

sub dispatch {
    my $self    = shift;
    my $command = shift;
    if ( my $method = $self->can("_command_${command}") ) {
        infof "Invoke command: %s::%s", ref $self, $command;
        my $success = $method->($self);
        if ($success) {
            infof "Complete!";
        }
        else {
            infof "Failed!";
            die;
        }
    }
    else {
        critf("Unknown command: %s", $command);
        die;
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

MHA::AWS - It's new $module

=head1 SYNOPSIS

    use MHA::AWS;

=head1 DESCRIPTION

MHA::AWS is ...

=head1 LICENSE

Copyright (C) FUJIWARA Shunichiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

FUJIWARA Shunichiro E<lt>fujiwara.shunichiro@gmail.comE<gt>

=cut

