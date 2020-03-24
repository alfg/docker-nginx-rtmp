#!/bin/sh

STUNNEL_CONFIG_FILE=/etc/stunnel/stunnel.conf

STUNNEL_CONNECTIONS=${STUNNEL_CONNECTIONS-live-api-s.facebook.com:443:19350}
STUNNEL_CONFIG_URLS=$(echo ${STUNNEL_CONNECTIONS} | sed "s/,/\n/g")

apply_config() {

	echo "Creating config"
## Standard config:

cat >${STUNNEL_CONFIG_FILE} <<!EOF
pid = /run/stunnel.pid

# Some performance tunings
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1

output = /var/log/stunnel.log
foreground = yes

# Service-level configuration
!EOF

## Tunnel configurations

for CONFIG_URL in $(echo ${STUNNEL_CONFIG_URLS}); do
	set -- $(echo ${CONFIG_URL} | sed "s/:/ /g")
	echo "Creating tunnel for $1"
	cat >>${STUNNEL_CONFIG_FILE} <<!EOF

[${1}]
client = yes
accept = 0.0.0.0:${3}
connect = ${1}:${2}
!EOF
done
}

if ! [ -f ${STUNNEL_CONFIG_FILE} ]; then
	apply_config
else
	echo "CONFIG EXISTS - Not creating!"
fi

echo "Starting server..."
/usr/bin/stunnel
