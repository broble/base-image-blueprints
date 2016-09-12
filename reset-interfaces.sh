#!/bin/bash
ifdown eth0
ifdown eth1
ifup eth0
ifup eth1
touch /etc/logtools/reset-interfaces-completed.txt
