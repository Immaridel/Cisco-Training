# Summary
This will allow you to migrate devices from an older NED to a newer NED.

# list devices
```
student@student-vm:~$ ssh nso-server
Last login: Wed Mar  6 14:01:00 2024 from 10.0.0.102
student@nso-server:~$ ncs_cli -C

student connected from 10.0.0.102 using ssh on nso-server
student@ncs# show devices list
NAME  ADDRESS    DESCRIPTION  NED ID              ADMIN STATE  
-------------------------------------------------------------
CE40  127.0.0.1  -            cisco-ios-cli-6.21  unlocked     
student@ncs# 
```

# copy & make netflow package
```
student@nso-server:~$ cp -r packages/netflow/ /var/opt/ncs/packages
student@nso-server:~$ make -C /var/opt/ncs/packages/netflow/src/
make: Entering directory '/var/opt/ncs/packages/netflow/src'
mkdir -p ../load-dir
/opt/ncs/current/bin/ncsc  `ls netflow-ann.yang  > /dev/null 2>&1 && echo "-a netflow-ann.yang"` \
              -c -o ../load-dir/netflow.fxs yang/netflow.yang
make: Leaving directory '/var/opt/ncs/packages/netflow/src'
student@nso-server:~$
```

# cat netflow.yang 
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

# reload packages
```
student@ncs# packages reload

>>> System upgrade is starting.
>>> Sessions in configure mode must exit to operational mode.
>>> No configuration changes can be performed until upgrade has completed.
>>> System upgrade has completed successfully.
reload-result {
    package cisco-ios-cli-6.21
    result true
}
reload-result {
    package netflow
    result true
}
student@ncs#
```

# run netflow services
```
student@ncs# config
Entering configuration mode terminal
student@ncs(config)# service
Possible completions:
  service-progress-monitoring   Service Progress Monitoring policies
  services                      The services managed by NCS
  ---                           
  service                       Modify use of network based services
student@ncs(config)# services netflow CE40 destination 10.100.0.1
student@ncs(config-netflow-CE40)# commit dry-run
cli {
    local-node {
        data  devices {
                  device CE40 {
                      config {
                          ip {
                              flow-export {
                                  source {
             +                        GigabitEthernet 1/0;
                                  }
             +                    version 5;
                                  destination {
             +                        ip 10.100.0.1;
                                  }
                              }
                          }
                          interface {
             +                GigabitEthernet 1/0 {
             +                }
                          }
                      }
                  }
              }
              services {
             +    netflow CE40 {
             +        destination 10.100.0.1;
             +    }
              }
    }
}
```

# packages reload
```
student@ncs# packages reload
```

# Migrate NED dry-run
```
student@ncs# devices migrate device [ CE40 ] old-ned-id cisco-ios-cli-6.21 new-ned-id cisco-ios-cli-6.85 verbose dry-run
```
 | LOTS of output

# Usage
There are many changes between the two device model versions. To find the
changes that affect the Netflow configuration, you must first interpret the package
reload error message from the previous step:

    netflow-template.xml:12 the tag: version is different for ned-ids: 
    cisco-ios-cli-6.21:cisco-ios-cli-6.21, cisco-ios-cli-6.85:cisco-ioscli-6.85

The error message tells you that there is an error in the line 12 of the configuration
template netflow-template.xml. This is related to the flow-export configuration, so
you may choose only the lines that are starting with <flow-export> XML tag, as
defined in the configuration template:

# Migrate NED dry-run with 'begin flow-export'
```
student@ncs# devices migrate device [ CE40 ] old-ned-id cisco-ios-cli-6.21 new-ned-id cisco-ios-cli-6.85 verbose dry-run | begin flow-export | more
{
    path /ios:ip/flow-export/version
    info node type has changed from leaf to non-presence container
    backward-compatible false
}
modified-path {
    path /ios:ip/flow-export/destination/port
    info leaf is now a list key
    backward-compatible false
}
modified-path {
    path /ios:ip/flow-export/destination/ip
    info leaf is now a list key
    backward-compatible false
}
modified-path {
    path /ios:ip/flow-export/destination
    info node type has changed from non-presence container to list
    backward-compatible false
}
```

# show running-config's service-meta-data in XML
```
student@ncs# show running-config devices device CE40 config ip flow-export | display xml | display service-meta-data 
<config xmlns="http://tail-f.com/ns/config/1.0">
  <devices xmlns="http://tail-f.com/ns/ncs">
    <device>
      <name>CE40</name>
      <config>
        <ip xmlns="urn:ios">
          <flow-export>
            <source>
              <GigabitEthernet refcounter="1">1/0</GigabitEthernet>
            </source>
            <version refcounter="1">5</version>
            <destination>
              <ip refcounter="1">10.100.0.1</ip>
            </destination>
          </flow-export>
        </ip>
      </config>
    </device>
  </devices>
</config>
```

# migrate ned without dry-run (no-networking)
```
student@ncs# devices migrate device [ CE40 ] old-ned-id cisco-ios-cli-6.21 new-ned-id cisco-ios-cli-6.85 no-networking
```

# Check device NED version
```
student@ncs# show devices list
NAME  ADDRESS    DESCRIPTION  NED ID              ADMIN STATE  
-------------------------------------------------------------
CE40  127.0.0.1  -            cisco-ios-cli-6.85  unlocked 
```

# Check configuration
```
student@ncs# config
Entering configuration mode terminal
student@ncs(config)# show full-configuration devices device CE40 config ip flow-export | display xml | display service-meta-data
<config xmlns="http://tail-f.com/ns/config/1.0">
  <devices xmlns="http://tail-f.com/ns/ncs">
    <device>
      <name>CE40</name>
      <config>
        <ip xmlns="urn:ios">
          <flow-export>
            <source>
              <GigabitEthernet refcounter="1">1/0</GigabitEthernet>
            </source>
          </flow-export>
        </ip>
      </config>
    </device>
  </devices>
</config>
```

# Change device to use flow-export versoin 5
```
student@ncs(config)# devices device CE40 config ip flow-export destination 10.100.0.1 2055
student@ncs(config-config)# ip flow-export version 5
student@ncs(config-config)# commit dry-run outformat xml
result-xml {
    local-node {
        data <devices xmlns="http://tail-f.com/ns/ncs">
               <device>
                 <name>CE40</name>
                 <config>
                   <ip xmlns="urn:ios">
                     <flow-export>
                       <version>
                         <version>5</version>
                       </version>
                       <destination>
                         <ip>10.100.0.1</ip>
                         <port>2055</port>
                       </destination>
                     </flow-export>
                   </ip>
                 </config>
               </device>
             </devices>
    }
}
```

# Add hard-coded version bullshit to template
```
student@nso-server:~$ vim /var/opt/ncs/packages/netflow/templates/netflow-template.xml 

<?xml version="1.0"?>
<config-template xmlns="http://tail-f.com/ns/config/1.0" servicepoint="netflow">
  <devices xmlns="http://tail-f.com/ns/ncs">
    <device>
      <name>{/device}</name>
      <config>
        <ip xmlns="urn:ios">
          <flow-export>
            <source>
              <GigabitEthernet>1/0</GigabitEthernet>
            </source>
            <?if-ned-id cisco-ios-cli-6.21:cisco-ios-cli-6.21?>
              <version>5</version>
              <destination>
                <ip>{/destination}</ip>
              </destination>
            <?elif-ned-id cisco-ios-cli-6.85:cisco-ios-cli-6.85?>
              <version>
                <version>5</version>
              </version>
              <destination>
                <ip>{/destination}</ip>
                <port>2055</port>
              </destination>
            <?end?>
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

# package reload
```
student@nso-server:~$ ncs_cli -C

User student last logged in 2024-09-24T18:31:31.161823+00:00, to nso-server, from 10.0.0.102 using cli-ssh
student connected from 10.0.0.102 using ssh on nso-server
student@ncs# packages reload
reload-result {
    package cisco-ios-cli-6.21
    result true
}
reload-result {
    package cisco-ios-cli-6.85
    result true
}
reload-result {
    package netflow
    result true
}
```

# Sync-to and re-deploy netflow to devices
```
student@ncs# devices device CE40 sync-to
result true
student@ncs# services netflow CE40 re-deploy 
student@ncs# 
System message at 2024-09-24 19:04:45...
Commit performed by student via ssh using cli.
```

# Show updated flow-export information
```
student@ncs# show running-config devices device CE40 config ip flow-export | display xml
<config xmlns="http://tail-f.com/ns/config/1.0">
  <devices xmlns="http://tail-f.com/ns/ncs">
    <device>
      <name>CE40</name>
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
              <ip>10.100.0.1</ip>
              <port>2055</port>
            </destination>
          </flow-export>
        </ip>
      </config>
    </device>
  </devices>
</config>
```