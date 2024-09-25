# netsim ports
```
ncs-netsim list for  /home/student/lab/netsim

name=IOS0 netconf=12022 snmp=11022 ipc=5010 cli=10022 dir=/home/student/lab/netsim/IOS/IOS0
```

# Add ISO0 to default authgroup with specific port/ned
### fetch ssh host key and sync-from device to populate CDB
```
student@nso-server:~/lab$ ncs_cli -C

User student last logged in 2024-09-25T14:43:39.411739+00:00, to nso-server, from 10.0.0.102 using cli-ssh
student connected from 10.0.0.102 using ssh on nso-server
student@ncs# config
Entering configuration mode terminal
student@ncs(config)# devices device IOS0 authgroup default address 127.0.0.1 port 12022 device-type netconf ned-id netconf    
student@ncs(config-device-IOS0)# state admin-state unlocked 
student@ncs(config-device-IOS0)# commit
Commit complete.
student@ncs(config-device-IOS0)# top
student@ncs(config)# exit
student@ncs# devices fetch-ssh-host-keys 
fetch-result {
    device IOS0
    result updated
    fingerprint {
        algorithm ssh-ed25519
        value a2:d4:2a:99:3e:a9:3b:f9:96:76:ea:fa:76:9d:33:a9
    }
}
student@ncs# devices sync-from 
sync-result {
    device IOS0
    result true
}
student@ncs#
```

# Enable devtools for user within NSO server
```
student@ncs# devtools true
```

# Create new build project using ISO0 device
```
student@ncs# config
student@ncs(config)# netconf-ned-builder project cisco-ios 1.0 device IOS0 local-user admin vendor Cisco
student@ncs(config-project-cisco-ios/1.0)# commit
Commit complete.
student@ncs(config-project-cisco-ios/1.0)# fetch-module-list 
student@ncs(config-project-cisco-ios/1.0)# module ?
Possible completions:
  iana-crypt-hash                ietf-datastores                          ietf-inet-types                    
  ietf-interfaces                ietf-ip                                  ietf-netconf                       
  ietf-netconf-monitoring        ietf-netconf-nmda                        ietf-netconf-notifications         
  ietf-netconf-partial-lock      ietf-netconf-with-defaults               ietf-network-instance              
  ietf-origin                    ietf-restconf                            ietf-restconf-monitoring           
  ietf-subscribed-notifications  ietf-subscribed-notifications-deviation  ietf-x509-cert-to-name             
  ietf-yang-library              ietf-yang-metadata                       ietf-yang-patch                    
  ietf-yang-push                 ietf-yang-push-deviation                 ietf-yang-schema-mount             
  ietf-yang-types                tailf-acm                                tailf-common                       
  tailf-common-monitoring        tailf-common-monitoring2                 tailf-common-query                 
  tailf-confd-monitoring         tailf-confd-monitoring2                  tailf-confd-progress               
  tailf-kicker                   tailf-last-login                         tailf-ned-cisco-ios                
  tailf-netconf-extensions       tailf-netconf-forward                    tailf-netconf-inactive             
  tailf-netconf-monitoring       tailf-netconf-query                      tailf-netconf-rollback             
  tailf-netconf-transactions     tailf-netconf-with-rollback-id           tailf-netconf-with-transaction-id  
  tailf-progress                 tailf-rollback                           tailf-tls                          
  tailf-webui                    tailf-xsd-types                          tailf-yang-patch                   
student@ncs(config-project-cisco-ios/1.0)#
```

# Add all discovered modules to the active project
```
student@ncs(config-project-cisco-ios/1.0)# module * * select
```
# Prune unwanted ones one at a time
```
student@ncs(config-project-cisco-ios/1.0)# module tailf-acm * deselect 
student@ncs(config-project-cisco-ios/1.0)# module tailf-tls * deselect 
student@ncs(config-project-cisco-ios/1.0)# module tailf-webui * deselect 
student@ncs(config-project-cisco-ios/1.0)# module ietf-yang-push * deselect 
student@ncs(config-project-cisco-ios/1.0)# module ietf-yang-push-deviation * deselect 
student@ncs(config-project-cisco-ios/1.0)# module ietf-subscribed-notifications * deselect
student@ncs(config-project-cisco-ios/1.0)# module ietf-subscribed-notifications-deviation * deselect
```

# build the NED (takes a couple minutes)
```
student@ncs(config-project-cisco-ios/1.0)# build-ned
```

# Copy new NED package into working packags directory
```
student@nso-server:~/lab$ cd
student@nso-server:~$ cp -r ncs-6.1-cisco-ios-nc-1.0.tar.gz /var/opt/ncs/packages/
student@nso-server:~$ ncs_cli -C

User student last logged in 2024-09-25T14:48:32.090171+00:00, to nso-server, from 10.0.0.102 using cli-ssh
student connected from 10.0.0.102 using ssh on nso-server
student@ncs# packages reload

>>> System upgrade is starting.
>>> Sessions in configure mode must exit to operational mode.
>>> No configuration changes can be performed until upgrade has completed.
reload-result {
    package cisco-ios-nc-1.0
    result true
}
```

# Change IOS0 to the new NED type
```
student@ncs# config
Entering configuration mode terminal
student@ncs(config)# devices device IOS0
student@ncs(config-device-IOS0)# device-type netconf ned-id cisco-ios-nc-1.0 
student@ncs(config-device-IOS0)# commit
Commit complete.
student@ncs(config-device-IOS0)# top
student@ncs(config)#
```

# Create static route for IOS0
```
student@ncs(config)# devices device IOS0 config ip route 10.100.0.0 255.255.0.0 1.0.0.1
student@ncs(config-config)# commit
Commit complete.
student@ncs(config-config)# top
student@ncs(config)# 
student@ncs# 
```

# Connect directly to IOS0 to validate static route
```
student@nso-server:~$ ssh admin@127.0.0.1 -p 10022
admin@127.0.0.1's password: 

User admin last logged in 2024-09-25T15:08:03.710112+00:00, to nso-server, from 127.0.0.1 using netconf-ssh
admin connected from 127.0.0.1 using ssh on nso-server

IOS0> enable 
IOS0# show running-config
no ip gratuitous-arps
no ip cef
ip finger
no ip http server
no ip http secure-server
no ip forward-protocol nd
ip route 10.100.0.0 255.255.0.0 1.0.0.1
no ipv6 cef
no dot11 syslog
interface Loopback0
```