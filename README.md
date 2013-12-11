# NAME

MHA::AWS - A support script for MySQL MasterHA running on AWS

# SYNOPSIS

    /etc/masterha_default.cnf

    [server default]
    master_ip_failover_script=mhaws master_ip_failover --interface_id=eni-xxxxxxxx
    master_ip_online_change_script=mhaws master_ip_online_change --interface_id=eni-xxxxxxxx
    shutdown_script=mhaws shutdown --interface_id=eni-xxxxxxxx

# DESCRIPTION

MHA::AWS is a support script for MySQL MasterHA which running on Amazon Web Service.

# LICENSE

Copyright (C) FUJIWARA Shunichiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

FUJIWARA Shunichiro <fujiwara.shunichiro@gmail.com>
