#!/bin/bash
name=$1
network=$2
pid=$(sudo lxc-info -n $name | grep 'PID' | cut -d ':' -f 2 |  tr -d '[[:space:]]')

sudo CNI_PATH=/usr/local/bin cnitool del $network /var/run/netns/$pid
