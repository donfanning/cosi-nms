#!/bin/sh -
# $Id$

addr=`echo $4 | cut -f 2 -d " " | cut -f 7,8,9,10 -d "."`
peer=`cat bgp_peers.conf | grep -v "#" | grep $addr: | cut -d: -f 2`

ovevent -s Major -c "Cisco Alarms" "" \
    .1.3.6.1.4.1.11.2.17.1.0.58916872 \
    .1.3.6.1.4.1.11.2.17.2.1.0 Integer 14 \
    .1.3.6.1.4.1.11.2.17.2.2.0 OctetString "$3" \
    .1.3.6.1.4.1.11.2.17.2.4.0 OctetString "BGP $2 - $peer [$addr] error: $1"

