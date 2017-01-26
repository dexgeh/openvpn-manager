#!/usr/bin/env sh

echo "Usage:"
echo "$0 server NAME"
echo "$0 client SERVER NAME"
echo "$0 check-expired-certs"

set -e
case "$1" in
  server)
    NAME="$2"
    mkdir $NAME
    echo -n 'Hostname (example.com): '
    read HOSTNAME
    echo "HOSTNAME=${HOSTNAME:-example.com}" >> $NAME/params.env.sh
    echo -n 'Port (1194): '
    read PORT
    echo "PORT=${PORT:-1194}" >> $NAME/params.env.sh
    echo -n 'Protocol (tcp/udp, default udp): '
    read PROTOCOL
    echo "PROTOCOL=${PROTOCOL:-udp}" >> $NAME/params.env.sh
    echo -n 'Subnet definition (default: 10.8.0.0 255.255.255.0): '
    read SUBNET_DEFINITION
    echo "SUBNET_DEFINITION=\"${SUBNET_DEFINITION:-10.8.0.0 255.255.255.0}\"" >> $NAME/params.env.sh
    cd $NAME
    CNAME=$NAME
    CAKEYFILE=$NAME.key
    CACRTFILE=$NAME.crt
    openssl req -new -newkey rsa:4096 -utf8 -sha256 \
      -days 3650 -nodes -x509 -subj "/CN=$CNAME" \
      -keyout $CAKEYFILE -out $CACRTFILE
    TAKEYFILE=$NAME.ta.key
    openvpn --genkey --secret $TAKEYFILE
    DHFILE=$NAME.dh.pem
    openssl dhparam -out $DHFILE 4096
    IPPFILE=$NAME.ipp.txt
    CONFFILE=$NAME.conf
    echo "port $PORT
proto $PROTOCOL
dev tun
ca $CACRTFILE
cert $CACRTFILE
key $CAKEYFILE
dh $DHFILE
server $SUBNET_DEFINITION
topology subnet
ifconfig-pool-persist $IPPFILE
client-to-client
keepalive 10 120
tls-auth $TAKEYFILE 0
cipher AES-256-CBC
persist-key
persist-tun
status $NAME.status.log
log-append $NAME.log
verb 4" > $CONFFILE
    zip $NAME.zip $CONFFILE $CACRTFILE $CAKEYFILE $DHFILE $TAKEYFILE
    ;;
  client)
    SERVER="$2"
    source $SERVER/params.env.sh
    NAME="$3"
    cd $SERVER
    CNAME=$SERVER.$NAME
    KEYFILE=$CNAME.key
    CSRFILE=$CNAME.csr
    openssl req -new -newkey rsa:4096 -sha256 \
      -nodes -subj "/CN=$CNAME" -keyout $KEYFILE -out $CSRFILE
    CAKEYFILE=$SERVER.key
    CACRTFILE=$SERVER.crt
    CRTFILE=$CNAME.crt
    openssl x509 -req -in $CSRFILE -CA $CACRTFILE -CAkey $CAKEYFILE \
      -days 3650 -out $CRTFILE -CAcreateserial
    TAKEYFILE=$SERVER.ta.key
    BASE_CONF="client
dev tun
remote $HOSTNAME $PORT
proto $PROTOCOL
resolv-retry infinite
nobind
persist-key
persist-tun
cipher AES-256-CBC
status $CNAME.status.log
log-append $CNAME.log
verb 4"
    BASE_KEY_EMBED="
<ca>
$(cat $CACRTFILE)
</ca>
<cert>
$(cat $CRTFILE)
</cert>
<key>
$(cat $KEYFILE)
</key>
<tls-auth>
$(cat $TAKEYFILE)
</tls-auth>

"
    # linux client
    CONFFILE=$CNAME.conf
    echo "
$BASE_CONF
ca $CACRTFILE
cert $CRTFILE
key $KEYFILE
tls-auth $TAKEYFILE 1
" > $CONFFILE
    zip $CNAME.linux.zip $CONFFILE $CACRTFILE $CRTFILE $KEYFILE $TAKEYFILE
    # windows client
    echo "
$BASE_CONF
ca [inline]
cert [inline]
key [inline]
tls-auth [inline] 1
key-direction 1
$BASE_KEY_EMBED
" > $CNAME.windows.ovpn
    # android client
    echo "
$BASE_CONF
key-direction 1
$BASE_KEY_EMBED
" > $CNAME.android.ovpn
    ;;
  check-expired-certs)
    echo Certificates expirations:
    find . -name \*.crt -exec \
      sh -c 'echo '{}'; openssl x509 -in '{}' -text' \; | \
      egrep '(crt|Not )'
    ;;
esac

