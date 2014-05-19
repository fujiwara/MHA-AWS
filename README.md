# NAME

MHA::AWS - A support script for "MySQL Master HA" running on AWS

# SYNOPSIS

    /etc/masterha_default.cnf

    [server default]
    master_ip_failover_script=mhaws master_ip_failover --interface_id=eni-xxxxxxxx
    master_ip_online_change_script=mhaws master_ip_online_change --interface_id=eni-xxxxxxxx
    shutdown_script=mhaws shutdown --interface_id=eni-xxxxxxxx

# DESCRIPTION

MHA::AWS is a support script for "MySQL Master HA" which running on Amazon Web Service.

# REQUIREMENTS

- One ENI (Elastic Network Interface) must be attached to the MySQL master instance. Clients accesses for the ENI's IP address.
- EC2 instance's "Name" tags must be resolved as DNS name in internal.
- root user must be allowed to ssh login between each MySQL instances.
- aws-cli is installed and available.

# FAILOVER FLOW

- 1 MHA detect master failure.
- 2 "mhaws master\_ip\_failover --command stop", ENI will be detached from the old master instance.
- 3 "mhaws shutdown --command (stopssh|stop)", Old master mysqld process will be killed (if ssh connection is available). Or old master instance will be stopped via AWS API (if ssh connection is NOT available).
- 4 MHA will elect the new master and set up replication.
- 5 "mhaws master\_ip\_failver --command start", ENI will be attached to the new master instance.

# SEE ALSO

[AWS::CLIWrapper](https://metacpan.org/pod/AWS::CLIWrapper), [https://code.google.com/p/mysql-master-ha/](https://code.google.com/p/mysql-master-ha/)

# LICENSE

Copyright (C) FUJIWARA Shunichiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

FUJIWARA Shunichiro <fujiwara.shunichiro@gmail.com>
