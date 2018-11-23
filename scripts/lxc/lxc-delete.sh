#!/bin/bash
name=$1
pid=$(sudo lxc-info -n $name | grep 'PID' | cut -d ':' -f 2 |  tr -d '[[:space:]]')

sudo lxc-stop -n $name
sudo lxc-destroy -n $name

sudo rm -rf /var/run/netns/$pid
