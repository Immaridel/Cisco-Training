# Enable commit-queues
```
student@student-vm:~$ ssh nso-server
Last login: Wed Mar  6 15:20:04 2024 from 10.0.0.102
student@nso-server:~$ ncs_cli -C

student connected from 10.0.0.102 using ssh on nso-server
student@ncs# config
Entering configuration mode terminal
student@ncs(config)# devices global-settings commit-queue enabled-by-default true
student@ncs(config)# devices global-settings commit-queue retry-timeout 30       
student@ncs(config)# devices global-settings commit-queue atomic false    
student@ncs(config)# devices global-settings commit-queue error-option rollback-on-error 
student@ncs(config)# commit
Commit complete.
student@ncs(config)# exit
student@ncs#
```

# Create static route for CE21
```
student@ncs# config
Entering configuration mode terminal
student@ncs(config)# services static-route CE21
student@ncs(config-static-route-CE21)# route 10.200.0.0/24 next-hop 10.0.0.2
student@ncs(config-route-10.200.0.0/24)# top
student@ncs(config)# commit
commit-queue {
    id 1727354701095
    status async
}
Commit complete.
```

# Show commit-queue summary
```
student@nso-server:~$ ncs_cli -C

User student last logged in 2024-09-26T12:34:08.56194+00:00, to nso-server, from 10.0.0.102 using cli-ssh
student connected from 10.0.0.102 using ssh on nso-server
student@ncs# show devices commit-queue summary
ID             STATUS     DEVICES   COMPLETED  NAME  
-----------------------------------------------------
1727354701095  completed  [ CE21 ]  [ CE21 ]         

```

# Add new static routes for both one good and one invald device
```
student@ncs# config
Entering configuration mode terminal
student@ncs(config)# services static-route CE11
student@ncs(config-static-route-CE11)# route 10.200.0.0/24 next-hop 10.0.0.2
student@ncs(config-route-10.200.0.0/24)# top
student@ncs(config)# services static-route CE22 
student@ncs(config-static-route-CE22)# route 10.200.0.0/24 next-hop 10.0.0.2
student@ncs(config-route-10.200.0.0/24)# top
student@ncs(config)# commit
commit-queue {
    id 1727354873933
    status async
}
Commit complete.
student@ncs(config)# *** ALARM connection-failure: Failed to connect to device CE11: connection refused: NEDCOM CONNECT: Connection refused (Connection refused) in new state
```

# check commit-queue
```
student@ncs# show devices commit-queue summary 
                                         WAITING  TRANSIENT                   
ID             STATUS     DEVICES        FOR      ERRORS     COMPLETED  NAME  
------------------------------------------------------------------------------
1727354873933  executing  [ CE11 CE22 ]  -        -          [ CE22 ]         

ID             STATUS     DEVICES   COMPLETED  NAME  
-----------------------------------------------------
1727354701095  completed  [ CE21 ]  [ CE21 ]         

```

# show commit-queue item detail
```
student@ncs# show devices commit-queue queue-item 1727354873933 details
devices commit-queue queue-item 1727354873933
 age              186
 status           executing
 devices          [ CE11 CE22 ]
 services         [ /ncs:services/static-route:static-route[static-route:device='CE11'] /ncs:services/static-route:static-route[static-route:device='CE22'] ]
 transient-errors [ CE11 ]
 completed        [ CE22 ]
 is-atomic        false
 modification CE11
  data       <ip xmlns="urn:ios">
               <route>
                 <ip-route-forwarding-list>
                   <prefix>10.200.0.0</prefix>
                   <mask>255.255.255.0</mask>
                   <forwarding-address>10.0.0.2</forwarding-address>
                 </ip-route-forwarding-list>
               </route>
             </ip>
             
  local-user student
 modification CE22
  local-user student
```

# show CE11 alarms
```
student@ncs# show alarms alarm-list alarm CE11
alarms alarm-list alarm CE11 connection-failure /devices/device[name='CE11'] ""
 is-cleared              false
 last-status-change      2024-09-26T12:47:55.761647+00:00
 last-perceived-severity major
 last-alarm-text         "Failed to connect to device CE11: connection refused: NEDCOM CONNECT: Connection refused (Connection refused) in new state"
 status-change 2024-09-26T12:47:55.761647+00:00
  received-time      2024-09-26T12:47:55.761647+00:00
  perceived-severity major
  alarm-text         "Failed to connect to device CE11: connection refused: NEDCOM CONNECT: Connection refused (Connection refused) in new state"
```

# Check netsim devices
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

# start CE11 netsim
```
student@nso-server:~/lab$ ncs-netsim start CE11
DEVICE CE11 OK STARTED
```

# Check commit-queue once CE11 is started
```
student@nso-server:~/lab$ ncs_cli -C

User student last logged in 2024-09-26T12:45:44.154692+00:00, to nso-server, from 10.0.0.102 using cli-ssh
student connected from 10.0.0.102 using ssh on nso-server
student@ncs# show devices commit-queue summary 
ID             STATUS     DEVICES        COMPLETED      NAME  
--------------------------------------------------------------
1727354701095  completed  [ CE21 ]       [ CE21 ]             
1727354873933  completed  [ CE11 CE22 ]  [ CE11 CE22 ]        

```

# Lock CE11 and attempt to delete services on device
```
student@ncs# devices commit-queue add-lock device CE11
commit-queue-id 1727355339161

student@ncs# config
Entering configuration mode terminal
student@ncs(config)# no services static-route CE11
student@ncs(config)# commit
commit-queue {
    id 1727355355617
    status async
}
Commit complete.
```

# configure ip address on device CE11
```
student@ncs(config)# devices device CE11 config interface GigabitEthernet 0/1
student@ncs(config-if)# ip address 10.200.0.101 255.255.255.0
student@ncs(config-if)# top
student@ncs(config)# commit
commit-queue {
    id 1727355445560
    status async
}
Commit complete.
student@ncs(config)# exit
```

# 
```
student@ncs# show devices commit-queue summary 
                                  WAITING   TRANSIENT                   
ID             STATUS   DEVICES   FOR       ERRORS     COMPLETED  NAME  
------------------------------------------------------------------------
1727355339161  locked   [ CE11 ]  -         -          -                
1727355355617  blocked  [ CE11 ]  [ CE11 ]  -          -                
1727355445560  blocked  [ CE11 ]  [ CE11 ]  -          -                

ID             STATUS     DEVICES        COMPLETED      NAME  
--------------------------------------------------------------
1727354701095  completed  [ CE21 ]       [ CE21 ]             
1727354873933  completed  [ CE11 CE22 ]  [ CE11 CE22 ]        

```

# List lock details
```
student@ncs# show devices commit-queue queue-item 1727355339161 details 
                                                     WAITING  TRANSIENT             IS                                              LOCAL    
ID             TAG  AGE  STATUS  DEVICES   SERVICES  FOR      ERRORS     COMPLETED  ATOMIC  NAME  REASON  DEVICE  ID  DEVICE  DATA  USER     
---------------------------------------------------------------------------------------------------------------------------------------------
1727355339161  -    582  locked  [ CE11 ]  -         -        -          -          true                              CE11    -     student  
```

# unlock queue-item
student@ncs# devices commit-queue queue-item 1727355339161 unlock

# Show committed changes once lock is cleared
```
student@ncs# show running-config devices device CE11 config interface GigabitEthernet 0/1
devices device CE11
 config
  interface GigabitEthernet0/1
   no switchport
   ip address 10.200.0.101 255.255.255.0
   no shutdown
  exit
 !
!
```