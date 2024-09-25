# RESTCONF Calls
```
GET - <get-config>, get
POST - <edit-config>, create
PUT - <edit-config>, replace
PATCH - <edit-config>, merge
DELETE - <edit-config>, delete
```

# GET Request
Authorization:  Basic Auth
Username:  oper
Password:  oper123
GET:  http://nso-server:8080/restconf/data/tailf-ncs:services/l3vpn:l3vpn
Headers: 
    Key:  Accept
    Value:  application/yang-data+json

```
{
  "l3vpn:l3vpn": [
    {
      "vpn-name": "Test",
      "vpn-id": 10001,
      "customer": "ACME",
      "modified": {
        "devices": ["PE11", "PE22"]
      },
      "directly-modified": {
        "devices": ["PE11", "PE22"]
      },
      "link": [
        {
          "id": "1",
          "device": "PE11",
          "interface": "0/0/0/1",
          "ip-address": "10.0.1.1",
          "mask": "255.255.255.252"
        },
        {
          "id": "2",
          "device": "PE22",
          "interface": "0/0/0/1",
          "ip-address": "10.0.2.1",
          "mask": "255.255.255.252"
        }
      ]
    }
  ]
}
```

# Post Request
Change URI to Parent: http://nso-server:8080/restconf/data/tailf-ncs:services
Duplicate GET tab
Change request type to POST
Go to Headers: 
    Key:  Content-Type
    Value:  application/yang-data+json
Click on BODY -> Select RAW
    Paste the below

```
{
  "l3vpn:l3vpn": [
    {
      "vpn-name": "ACME",
      "vpn-id": 10002,
      "customer": "ACME",
      "link": [
        {
          "id": "1",
          "device": "PE11",
          "interface": "0/0/0/2",
          "ip-address": "10.100.100.1",
          "mask": "255.255.255.252"
        },
        {
          "id": "2",
          "device": "PE22",
          "interface": "0/0/0/2",
          "ip-address": "10.100.200.1",
          "mask": "255.255.255.252"
        }
      ]
    }
  ]
}
```
Post and ensure 201 response

# Validate New Service Instance
Authorization:  Basic Auth
Username:  monitor
Password:  monitor123
GET:  http://nso-server:8080/restconf/data/tailf-ncs:services/l3vpn:l3vpn?fields=vpn-name;link
Headers: 
    Key:  Accept
    Value:  application/yang-data+json
```
{
  "l3vpn:l3vpn": [
    {
      "vpn-name": "ACME",
      "link": [
        {
          "id": "1",
          "device": "PE11",
          "interface": "0/0/0/2",
          "ip-address": "10.100.100.1",
          "mask": "255.255.255.252"
        },
        {
          "id": "2",
          "device": "PE22",
          "interface": "0/0/0/2",
          "ip-address": "10.100.200.1",
          "mask": "255.255.255.252"
        }
      ]
    },
    {
      "vpn-name": "Test",
      "link": [
        {
          "id": "1",
          "device": "PE11",
          "interface": "0/0/0/1",
          "ip-address": "10.0.1.1",
          "mask": "255.255.255.252"
        },
        {
          "id": "2",
          "device": "PE22",
          "interface": "0/0/0/1",
          "ip-address": "10.0.2.1",
          "mask": "255.255.255.252"
        }
      ]
    }
  ]
}
```

# snmp v2c configuration (version parameter not specified)
```
student@ncs# show running-config snmp agent
student@ncs(config)# snmp agent enabled
student@ncs(config)# snmp agent udp-port 4000
student@ncs(config)# snmp community public sec-name public
student@ncs(config)# snmp agent version v2c
student@ncs(config-community-public)# top
student@ncs(config)# commit
Commit complete.
```

# Validate
```
student@nso-server:~$ snmpwalk -v 2c -c public -M /opt/ncs/current/src/ncs/snmp/mibs/ -m TAILF-ALARM-MIB 127.0.0.1:4000 TAILF-TOP-MIB::tfModules
TAILF-ALARM-MIB::tfAlarmNumber.0 = Gauge32: 0
TAILF-ALARM-MIB::tfAlarmLastChanged.0 = STRING: 2024-2-1,20:19:21.4,+0:0
```

# Screw up a device
```
student@nso-server:~$ ncs_cli -C

User student last logged in 2024-09-23T20:06:25.976004+00:00, to nso-server, from 127.0.0.1 using cli-ssh
student connected from 127.0.0.1 using ssh on nso-server
student@ncs# config
Entering configuration mode terminal
student@ncs(config)# devices device PE11 config interface Loopback 10 ipv4 address 1.3.3.7 /32
student@ncs(config-if)# top
student@ncs(config)# commit no-networking 
Commit complete.
student@ncs(config)# devices device PE11 check-sync
result out-of-sync
info Out of sync due to no-networking or failed commit-queue commits
student@ncs(config)# *** ALARM out-of-sync: Out of sync due to no-networking or failed commit-queue commits
student@ncs(config)# 
student@ncs#
```

# Check screwed up device (tfAlarmCleared.1 = INTEGER: false(2))
```
student@nso-server:~$ snmpwalk -v 2c -c public -M /opt/ncs/current/src/ncs/snmp/mibs/ -m TAILF-ALARM-MIB 127.0.0.1:4000 TAILF-TOP-MIB::tfModules
TAILF-ALARM-MIB::tfAlarmNumber.0 = Gauge32: 1
TAILF-ALARM-MIB::tfAlarmLastChanged.0 = STRING: 2024-9-23,20:11:58.3,+0:0
TAILF-ALARM-MIB::tfAlarmType.1 = STRING: out-of-sync
TAILF-ALARM-MIB::tfAlarmDevice.1 = STRING: PE11
TAILF-ALARM-MIB::tfAlarmObject.1 = STRING: /ncs:devices/ncs:device[ncs:name='PE11']
TAILF-ALARM-MIB::tfAlarmObjectOID.1 = OID: SNMPv2-SMI::zeroDotZero
TAILF-ALARM-MIB::tfAlarmObjectStr.1 = STRING: 
TAILF-ALARM-MIB::tfAlarmSpecificProblem.1 = STRING: 
TAILF-ALARM-MIB::tfAlarmEventType.1 = INTEGER: other(1)
TAILF-ALARM-MIB::tfAlarmProbableCause.1 = Gauge32: 0
TAILF-ALARM-MIB::tfAlarmOrigTime.1 = STRING: 2024-9-23,20:11:58.3,+0:0
TAILF-ALARM-MIB::tfAlarmTime.1 = STRING: 2024-9-23,20:11:58.3,+0:0
TAILF-ALARM-MIB::tfAlarmSeverity.1 = INTEGER: major(4)
TAILF-ALARM-MIB::tfAlarmCleared.1 = INTEGER: false(2)
TAILF-ALARM-MIB::tfAlarmText.1 = STRING: Out of sync due to no-networking or failed commit-queue commits
```

# Repair Device
```
student@nso-server:~$ ncs_cli -C

User student last logged in 2024-09-23T20:11:05.287863+00:00, to nso-server, from 127.0.0.1 using cli-ssh
student connected from 127.0.0.1 using ssh on nso-server
student@ncs# devices device PE11 sync-to
result true
student@ncs# exit
```

# Check again (tfAlarmCleared.1 = INTEGER: true(1))
```
student@nso-server:~$ snmpwalk -v 2c -c public -M /opt/ncs/current/src/ncs/snmp/mibs/ -m TAILF-ALARM-MIB 127.0.0.1:4000 TAILF-TOP-MIB::tfModules
TAILF-ALARM-MIB::tfAlarmNumber.0 = Gauge32: 1
TAILF-ALARM-MIB::tfAlarmLastChanged.0 = STRING: 2024-9-23,20:12:47.4,+0:0
TAILF-ALARM-MIB::tfAlarmType.1 = STRING: out-of-sync
TAILF-ALARM-MIB::tfAlarmDevice.1 = STRING: PE11
TAILF-ALARM-MIB::tfAlarmObject.1 = STRING: /ncs:devices/ncs:device[ncs:name='PE11']
TAILF-ALARM-MIB::tfAlarmObjectOID.1 = OID: SNMPv2-SMI::zeroDotZero
TAILF-ALARM-MIB::tfAlarmObjectStr.1 = STRING: 
TAILF-ALARM-MIB::tfAlarmSpecificProblem.1 = STRING: 
TAILF-ALARM-MIB::tfAlarmEventType.1 = INTEGER: other(1)
TAILF-ALARM-MIB::tfAlarmProbableCause.1 = Gauge32: 0
TAILF-ALARM-MIB::tfAlarmOrigTime.1 = STRING: 2024-9-23,20:11:58.3,+0:0
TAILF-ALARM-MIB::tfAlarmTime.1 = STRING: 2024-9-23,20:12:47.4,+0:0
TAILF-ALARM-MIB::tfAlarmSeverity.1 = INTEGER: major(4)
TAILF-ALARM-MIB::tfAlarmCleared.1 = INTEGER: true(1)
TAILF-ALARM-MIB::tfAlarmText.1 = STRING: Out of sync due to no-networking or failed commit-queue commits
```

# Check snmp agent config values
```
student@nso-server:~$ ncs_cli -C

User student last logged in 2024-09-23T20:12:35.593585+00:00, to nso-server, from 127.0.0.1 using cli-ssh
student connected from 127.0.0.1 using ssh on nso-server
student@ncs# show running-config snmp agent
snmp agent enabled
snmp agent ip    0.0.0.0
snmp agent udp-port 4000
snmp agent version v2c
snmp agent max-message-size 50000
```