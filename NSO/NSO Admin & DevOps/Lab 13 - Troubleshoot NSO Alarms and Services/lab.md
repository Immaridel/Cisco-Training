# Copy and compile netflow package
```
student@student-vm:~$ ssh nso-server
Last login: Wed Mar  6 15:03:06 2024 from 10.0.0.102
student@nso-server:~$ cp -r packages/netflow /var/opt/ncs/packages/
student@nso-server:~$ make -B -C /var/opt/ncs/packages/netflow/src/
make: Entering directory '/var/opt/ncs/packages/netflow/src'
mkdir -p ../load-dir
/opt/ncs/current/bin/ncsc  `ls netflow-ann.yang  > /dev/null 2>&1 && echo "-a netflow-ann.yang"` \
              -c -o ../load-dir/netflow.fxs yang/netflow.yang
make: Leaving directory '/var/opt/ncs/packages/netflow/src'
student@nso-server:~$
```

# Reload and view expected error
```
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
    package l3mplsvpn
    result true
}
reload-result {
    package netflow
    result false
    info netflow-template.xml:2 Unknown servicepoint: netflow-export
}
student@ncs# 
System message at 2024-09-25 16:15:09...
    Subsystem stopped: ncs-dp-1-cisco-ios-cli-6.85:IOSDp
student@ncs# 
System message at 2024-09-25 16:15:09...
    Subsystem started: ncs-dp-2-cisco-ios-cli-6.85:IOSDp
student@ncs# *** ALARM package-load-failure: netflow-template.xml:2 Unknown servicepoint: netflow-export
```

# Use the handle-alarm action for the CE11 connection-failure alarm and set the state to investigation
```
student@ncs# alarms alarm-list alarm CE11 connection-failure /devices/device[name='CE11'] "" handle-alarm description "Looking into CE11 evice configuration" state investigation 
student@ncs# 
```

# View updated alarms
```
student@ncs# show alarms alarm-list alarm CE11
alarms alarm-list alarm CE11 connection-failure /devices/device[name='CE11'] ""
 is-cleared                 false
 last-status-change         2024-02-06T14:56:23.987772+00:00
 last-perceived-severity    major
 last-alarm-text            "Failed to connect to device CE11: connection refused: NEDCOM CONNECT: Connection refused (Connection refused) in new state"
 status-change 2024-02-06T14:56:23.987772+00:00
  received-time      2024-02-06T14:56:23.987772+00:00
  perceived-severity major
  alarm-text         "Failed to connect to device CE11: connection refused: NEDCOM CONNECT: Connection refused (Connection refused) in new state"
 last-alarm-handling-change 2024-09-25T18:11:29.624544+00:00
 alarm-handling 2024-09-25T18:11:29.624544+00:00
  state       investigation
  user        student
  description "Looking into CE11 evice configuration"
student@ncs# 
```

# Check live devices
```
student@nso-server:~$ cd lab
student@nso-server:~/lab$ ncs-netsim is-alive
DEVICE CE11 FAIL
DEVICE CE12 OK
DEVICE CE21 OK
DEVICE CE22 OK
DEVICE PE11 OK
DEVICE PE22 OK
```

# Start unalived netsim
```
student@nso-server:~/lab$ ncs-netsim start CE11
DEVICE CE11 OK STARTED
```

# sync-from device and resove alarm
```
student@nso-server:~/lab$ ncs_cli -C

User student last logged in 2024-09-25T18:10:01.998987+00:00, to nso-server, from 10.0.0.102 using cli-ssh
student connected from 10.0.0.102 using ssh on nso-server
student@ncs# devices device CE11 sync-from
result true

student@ncs# alarms alarm-list alarm CE11 connection-failure /devices/device[name='CE11'] "" handle-alarm description "NetSim device was down. Resolved." state closed
student@ncs#
```

# View resolved alarm
```
student@ncs# show alarms alarm-list alarm CE11
alarms alarm-list alarm CE11 connection-failure /devices/device[name='CE11'] ""
 is-cleared                 true
 last-status-change         2024-09-25T18:17:31.359472+00:00
 last-perceived-severity    major
 last-alarm-text            "Failed to connect to device CE11: connection refused: NEDCOM CONNECT: Connection refused (Connection refused) in new state"
 status-change 2024-02-06T14:56:23.987772+00:00
  received-time      2024-02-06T14:56:23.987772+00:00
  perceived-severity major
  alarm-text         "Failed to connect to device CE11: connection refused: NEDCOM CONNECT: Connection refused (Connection refused) in new state"
 status-change 2024-09-25T18:17:31.359472+00:00
  received-time      2024-09-25T18:17:31.359472+00:00
  perceived-severity cleared
  alarm-text         "Connected as student"
 last-alarm-handling-change 2024-09-25T18:18:19.719901+00:00
 alarm-handling 2024-09-25T18:11:29.624544+00:00
  state       investigation
  user        student
  description "Looking into CE11 evice configuration"
 alarm-handling 2024-09-25T18:18:19.719901+00:00
  state       closed
  user        student
  description "NetSim device was down. Resolved."
```

# show package-load-failure alarms
```
student@ncs# show alarms alarm-list alarm ncs package-load-failure 
alarms alarm-list alarm ncs package-load-failure /packages/package[name='netflow'] ""
 is-cleared              false
 last-status-change      2024-09-25T16:15:09.197821+00:00
 last-perceived-severity critical
 last-alarm-text         "netflow-template.xml:2 Unknown servicepoint: netflow-export"
 status-change 2024-09-25T16:15:09.197821+00:00
  received-time      2024-09-25T16:15:09.197821+00:00
  perceived-severity critical
  alarm-text         "netflow-template.xml:2 Unknown servicepoint: netflow-export"
```

# Set alarm state to 'investigation'
```
student@ncs# alarms alarm-list alarm ncs package-load-failure /packages/package[name='netflow'] "" handle-alarm description "Fixing the netflow service" state investigation 
```

# View netflow.yang 
```
student@nso-server:~$ cat /var/opt/ncs/packages/netflow/src/yang/netflow.yang 
module netflow {
  namespace "http://cisco.com/example/netflow";
  prefix netflow;

  import ietf-inet-types {
    prefix inet;
  }
  import tailf-ncs {
    prefix ncs;
  }
  import tailf-common {
    prefix tailf;
  }
  augment /ncs:services {
    list netflow {
      description "Export NetFlow service";
      key device;

      uses ncs:service-data;
      ncs:servicepoint "netflow";

      leaf device {
        tailf:info "Device to export NetFlow data from";
        type leafref {
          path "/ncs:devices/ncs:device/ncs:name";
        }
      }

      leaf destination {
        tailf:info "Address to export NetFlow data to";
        type inet:ipv4-address;
      }
    }
  }
}
```

# Edit the netflow template
```
vim /var/opt/ncs/packages/netflow/templates/netflow-template.xml
<?xml version="1.0"?>
<config-template xmlns="http://tail-f.com/ns/config/1.0" servicepoint="netflow-export">
  <devices xmlns="http://tail-f.com/ns/ncs">
    <device>
      <name>{/device}</name>
      <config>
        <ip xmlns="urn:ios">
          <flow-export>
            <source>
                <GigabitEthernet>1/0</GigabitEthernet>
              </source>
            <version>
              <version>5</version>
            </version>
            <destination>
              <ip>{/destination}</ip>
              <port>2055</port>
            </destination>
          </flow-export>
        </ip>
        <interface xmlns="urn:ios">
          <GigabitEthernet>
            <name>1/0</name>
          </GigabitEthernet>
        </interface>
      </config>
    </device>
  </devices>
</config-template>
```

# pReload the packages
```
student@ncs# packages reload
reload-result {
    package cisco-ios-cli-6.85
    result true
}
reload-result {
    package cisco-iosxr-cli-7.41
    result true
}
reload-result {
    package l3mplsvpn
    result true
}
reload-result {
    package netflow
    result false
    info netflow-template.xml:2 Unknown servicepoint: netflow-export
}
student@ncs# 
System message at 2024-09-25 18:23:58...
    Subsystem stopped: ncs-dp-2-cisco-ios-cli-6.85:IOSDp
student@ncs# 
System message at 2024-09-25 18:23:58...
    Subsystem started: ncs-dp-3-cisco-ios-cli-6.85:IOSDp
```

# Close alarm
```
student@ncs# alarms alarm-list alarm ncs package-load-failure /packages/package[name='netflow'] "" handle-alarm description "Fixed the glitch" state closed
```

# View alarms summary
```
student@ncs# show alarms summary 
alarms summary indeterminates 0
alarms summary criticals 1
alarms summary majors 0
alarms summary minors 0
alarms summary warnings 0
```