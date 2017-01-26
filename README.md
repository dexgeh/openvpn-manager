openvpn-manager
===============

An helper script to generate and manage multiple openvpn set-ups,
that generates certificates and configurations for linux (server and client),
windows and android (client only).

```
Usage:
  ./openvpn-manager.sh server NAME
  ./openvpn-manager.sh client SERVER NAME
  ./openvpn-manager.sh check-expired-certs
```

commands
--------

`server`: asks for hostname, port, protocol and network configuration, with default values; creates a directory named as the server name.
An example output:
```
$ ./openvpn-config-manager.sh server testvpn
Usage:
./openvpn-config-manager.sh server NAME
./openvpn-config-manager.sh client SERVER NAME
Hostname (example.com):
Port (1194):
Protocol (tcp/udp, default udp):
Subnet definition (default: 10.8.0.0 255.255.255.0):
[...]
$ ls -1 testvpn/
params.env.sh
testvpn.conf
testvpn.crt
testvpn.dh.pem
testvpn.key
testvpn.ta.key
testvpn.srl
testvpn.zip
```
The packaged zip contains the linux configuration needed, to be dropped in the /etc/openvpn directory (or /etc/openvpn/server on some distros) of a linux server.

`client`: asks for the server name and find the appropriate configuration,
load it and generate multiple client configurations.
Example output:
```
$ ./openvpn-config-manager.sh client testvpn myclient
[...]
$ ls -1 testvpn/testvpn.myclient.*
testvpn/testvpn.myclient.conf
testvpn/testvpn.myclient.crt
testvpn/testvpn.myclient.csr
testvpn/testvpn.myclient.key
testvpn/testvpn.myclient.android.ovpn
testvpn/testvpn.myclient.windows.ovpn
testvpn/testvpn.myclient.linux.zip
```

`check-expired-certs`: print certificates expiration dates, useful for routine checks.
