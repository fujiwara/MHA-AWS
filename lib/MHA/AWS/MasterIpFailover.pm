package MHA::AWS::MasterIpFailover;

use strict;
use warnings;
use parent "MHA::AWS";
use Log::Minimal;

sub _command_stop {
    my $self = shift;
    infof "stop";
    my $res = $self->ec2("detach-network-interface", {
        attachment_id => $self->attachment_id,
    });
    infof "result: %s", ddf $res;
    my $timeout = time + $MHA::AWS::FAILOVER_TIMEOUT;
  DETACHED:
    while ( time < $timeout ) {
        $res = $self->ec2("describe-network-interfaces", {
            network_interface_ids => $self->interface_id,
        });
        if ( $res->{NetworkInterfaces}->[0]->{Status} eq "available" ) {
            infof "detach completed.";
            return 1;
        }
        sleep $MHA::AWS::CHECK_INTERVAL;
    }
    critf "TIMEOUT: %d sec. Can't complete detach-network-interface: %s", $MHA::AWS::FAILOVER_TIMEOUT, $self->interface_id;
    return;
}

sub _command_start {
    my $self = shift;
    infof "start";
    my $res = $self->ec2("attach-network-interface", {
        network_interface_id => $self->interface_id,
        instance_id          => $self->new_master_instance_id,
        device_index         => 2,
    });
    infof "result: %s", ddf $res;
    my $timeout = time + $MHA::AWS::FAILOVER_TIMEOUT;
  ATTACHED:
    while ( time < $timeout ) {
        $res = $self->ec2("describe-network-interfaces", {
            network_interface_ids => $self->interface_id,
        });
        my $if = $res->{NetworkInterfaces}->[0];
        if ( $if->{Status} eq "in-use"
          && $if->{Attachment}
          && $if->{Attachment}->{Status} eq "attached"
          && $self->ping($self->vip)
        )
        {
            infof "attache completed.";
            return 1;
        }
        sleep $MHA::AWS::CHECK_INTERVAL;
    }
    critf "TIMEOUT %d sec. Can't complete attach-network-interface: %s", $MHA::AWS::FAILOVER_TIMEOUT, $self->interface_id;
    return;
}

sub _command_status {
    my $self = shift;
    infof "status";
    if ($self->orig_master_instance_id eq $self->current_attached_instance_id) {
        return 1;
    }
    else {
        critf "orig_master_instance_id: %s != current_attached_instance_id: %s", $self->orig_master_instance_id, $self->current_attached_instance_id;
        return;
   }
}

1;
