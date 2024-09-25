# Copy package to NSO packages dir
student@student-vm:~$ ssh nso-server
Last login: Wed Mar  6 14:45:01 2024 from 10.0.0.102
student@nso-server:~$ cp -r packages/l3vpn-rfs/ /var/opt/ncs/packages/

# make package
# Parameter -B will unconditionally make all targets specified in the Makefile. 
# Parameter -C dir will change to directory dir before
reading the makefiles or doing anything else.
student@nso-server:~$ make -B -C /var/opt/ncs/packages/l3vpn-rfs/src/
make: Entering directory '/var/opt/ncs/packages/l3vpn-rfs/src'
mkdir -p ../load-dir
mkdir -p java/src//
/opt/ncs/current/bin/ncsc  `ls l3vpn-rfs-ann.yang  > /dev/null 2>&1 && echo "-a l3vpn-rfs-ann.yang"` \
              -c -o ../load-dir/l3vpn-rfs.fxs yang/l3vpn-rfs.yang
make: Leaving directory '/var/opt/ncs/packages/l3vpn-rfs/src'
student@nso-server:~$

# reload packages
student@nso-server:~$ ncs_cli -C

student connected from 10.0.0.102 using ssh on nso-server
student@ncs# packages reload

>>> System upgrade is starting.
>>> Sessions in configure mode must exit to operational mode.
>>> No configuration changes can be performed until upgrade has completed.
>>> System upgrade has completed successfully.
reload-result {
    package cisco-ios-cli-6.85
    result true
}
reload-result {
    package cisco-iosxr-cli-7.41
    result true
}
reload-result {
    package l3vpn-rfs
    result true
}
student@ncs# 
System message at 2024-09-25 15:44:40...
    Subsystem stopped: ncs-dp-1-cisco-ios-cli-6.85:IOSDp
student@ncs# 
System message at 2024-09-25 15:44:40...
    Subsystem started: ncs-dp-2-cisco-ios-cli-6.85:IOSDp

# Configure CE22 VPN link using the l3vpn-rfs service
student@ncs# config
Entering configuration mode terminal
student@ncs(config)# l3vpn-rfs vpn1 link CustomerA device CE22 interface 0/0 ip-address 10.100.0.1 mask 255.255.0.0
student@ncs(config-link-CustomerA)# commit
Commit complete.
student@ncs(config-link-CustomerA)# top
student@ncs(config)# exit
student@ncs# exit

# Show ncs-netsim list
student@nso-server:~$ cd lab/netsim/
student@nso-server:~/lab/netsim$ ncs-netsim list
ncs-netsim list for  /home/student/lab/netsim

name=CE11 netconf=12022 snmp=11022 ipc=5010 cli=10022 dir=/home/student/lab/netsim/CE/CE0 
name=CE12 netconf=12023 snmp=11023 ipc=5011 cli=10023 dir=/home/student/lab/netsim/CE/CE1 
name=CE21 netconf=12024 snmp=11024 ipc=5012 cli=10024 dir=/home/student/lab/netsim/CE/CE2 
name=CE22 netconf=12025 snmp=11025 ipc=5013 cli=10025 dir=/home/student/lab/netsim/CE/CE3 
name=PE11 netconf=12026 snmp=11026 ipc=5014 cli=10026 dir=/home/student/lab/netsim/PE/PE0 
name=PE22 netconf=12027 snmp=11027 ipc=5015 cli=10027 dir=/home/student/lab/netsim/PE/PE1

# stop CE22
student@nso-server:~/lab/netsim$ ncs-netsim stop CE22
DEVICE CE22 STOPPED

# Attempt to connect to all devices
# CE22 will show a failure
student@nso-server:~/lab/netsim$ ncs_cli -C

User student last logged in 2024-09-25T15:43:20.801361+00:00, to nso-server, from 10.0.0.102 using cli-ssh
student connected from 10.0.0.102 using ssh on nso-server
student@ncs# devices connect
...
connect-result {
    device CE22
    result false
    info Failed to connect to device CE22: connection refused: NEDCOM CONNECT: Connection refused (Connection refused) in new state
}
...
student@ncs# *** ALARM connection-failure: Failed to connect to device CE22: connection refused: NEDCOM CONNECT: Connection refused (Connection refused) in new state

# Show CE22 alarms
student@ncs# show alarms alarm-list alarm CE22
alarms alarm-list alarm CE22 connection-failure /devices/device[name='CE22'] ""
 is-cleared              false
 last-status-change      2024-09-25T15:48:10.185368+00:00
 last-perceived-severity major
 last-alarm-text         "Failed to connect to device CE22: connection refused: NEDCOM CONNECT: Connection refused (Connection refused) in new state"
 status-change 2024-09-25T15:48:10.185368+00:00
  received-time      2024-09-25T15:48:10.185368+00:00
  perceived-severity major
  alarm-text         "Failed to connect to device CE22: connection refused: NEDCOM CONNECT: Connection refused (Connection refused) in new state"
 
# Add a new device CE22v2 that will replace the faulty CE22 one.
# NetSim device names must be unique.
# Before adding a device, you will need to give some permissions to the host keys,
# used by the NetSim devices, since it was set up by another non-student user. The
# RSA keys are located in the /opt/ncs/current/netsim/confd/etc/confd/ssh/
# ssh_host_rsa_key and /opt/ncs/current/netsim/confd/etc/confd/ssh/
# ssh_host_ed25519_key.
student@nso-server:~/lab/netsim$ sudo chmod 644 /opt/ncs/current/netsim/confd/etc/confd/ssh/ssh_host_rsa_key
student@nso-server:~/lab/netsim$ sudo chmod 644 /opt/ncs/current/netsim/confd/etc/confd/ssh/ssh_host_ed25519_key
student@nso-server:~/lab/netsim$ ncs-netsim add-device /var/opt/ncs/packages/cisco-ios-cli-6.85 CE22v2
DEVICE CE22v2 CREATED

# Start created CE22v2 device
student@nso-server:~/lab/netsim$ ncs-netsim start CE22v2
DEVICE CE22v2 OK STARTED

# List all netsim devices, showing CE22v2 running
student@nso-server:~/lab/netsim$ ncs-netsim list
ncs-netsim list for  /home/student/lab/netsim

name=CE11 netconf=12022 snmp=11022 ipc=5010 cli=10022 dir=/home/student/lab/netsim/CE/CE0 
name=CE12 netconf=12023 snmp=11023 ipc=5011 cli=10023 dir=/home/student/lab/netsim/CE/CE1 
name=CE21 netconf=12024 snmp=11024 ipc=5012 cli=10024 dir=/home/student/lab/netsim/CE/CE2 
name=CE22 netconf=12025 snmp=11025 ipc=5013 cli=10025 dir=/home/student/lab/netsim/CE/CE3 
name=PE11 netconf=12026 snmp=11026 ipc=5014 cli=10026 dir=/home/student/lab/netsim/PE/PE0 
name=PE22 netconf=12027 snmp=11027 ipc=5015 cli=10027 dir=/home/student/lab/netsim/PE/PE1 
name=CE22v2 netconf=12028 snmp=11028 ipc=5016 cli=10028 dir=/home/student/lab/netsim/CE22v2/CE22v2 

# Change CE22 port to use new device's port 10028
student@nso-server:~/lab/netsim$ ncs_cli -C

User student last logged in 2024-09-25T15:48:00.555614+00:00, to nso-server, from 10.0.0.102 using cli-ssh
student connected from 10.0.0.102 using ssh on nso-server
student@ncs# config
Entering configuration mode terminal
student@ncs(config)# devices device CE22 port 10028
student@ncs(config-device-CE22)# top
student@ncs(config)# commit
Commit complete.

# fetch keys, check-sync, and sync-to new device
student@ncs# devices device CE22 ssh fetch-host-keys 
result updated
fingerprint {
    algorithm ssh-rsa
    value 70:d0:17:8a:49:25:56:4e:29:a1:36:ec:c0:e8:e0:3c
}
student@ncs# devices device CE22 check-sync 
result out-of-sync
info got: 8b4d5a2317f421fa0498afac619e0d0c expected: b0f2ffddb643eede2f248adb5df587

student@ncs# *** ALARM out-of-sync: got: 8b4d5a2317f421fa0498afac619e0d0c expected: b0f2ffddb643eede2f248adb5df587

student@ncs# devices device CE22 sync-to 
result true

# Connect to and validate device config
student@nso-server:~/lab/netsim$ ncs-netsim cli-c CE22v2

User admin last logged in 2024-09-25T15:59:19.600994+00:00, to nso-server, from 127.0.0.1 using cli-ssh
admin connected from 10.0.0.102 using ssh on nso-server
CE22v2# show running-config router
router bgp 65000
 address-family ipv4 unicast vrf vpn1
  neighbor 10.100.0.1 remote-as 65001
  exit-address-family
 !
!
