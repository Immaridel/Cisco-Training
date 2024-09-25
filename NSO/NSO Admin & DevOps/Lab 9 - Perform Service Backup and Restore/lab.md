# Perform manual backup and show running-config for static routes
```
student@student-vm:~$ ssh nso-server
Last login: Wed Mar  6 14:30:32 2024 from 10.0.0.102
student@nso-server:~$ ls /var/opt/ncs/packages/
cisco-ios-cli-6.85  cisco-iosxr-cli-7.41  static-route
student@nso-server:~$ mkdir backup
student@nso-server:~$ tar zcvf backup/static_route.tar.gz /var/opt/ncs/packages/static-route/
tar: Removing leading `/' from member names
/var/opt/ncs/packages/static-route/
/var/opt/ncs/packages/static-route/README
/var/opt/ncs/packages/static-route/templates/
/var/opt/ncs/packages/static-route/templates/static-route-template.xml
/var/opt/ncs/packages/static-route/load-dir/
/var/opt/ncs/packages/static-route/load-dir/static-route.fxs
/var/opt/ncs/packages/static-route/package-meta-data.xml
/var/opt/ncs/packages/static-route/python/
/var/opt/ncs/packages/static-route/python/static_route/
/var/opt/ncs/packages/static-route/python/static_route/static_route.py
/var/opt/ncs/packages/static-route/python/static_route/__init__.py
/var/opt/ncs/packages/static-route/src/
/var/opt/ncs/packages/static-route/src/yang/
/var/opt/ncs/packages/static-route/src/yang/static-route.yang
/var/opt/ncs/packages/static-route/src/java/
/var/opt/ncs/packages/static-route/src/java/src/
/var/opt/ncs/packages/static-route/src/Makefile
student@nso-server:~$ ncs_cli -C

student connected from 10.0.0.102 using ssh on nso-server
student@ncs# show running-config services static-route 
services static-route CE11
 route 10.100.0.0/24
  next-hop 10.0.0.1
 !
!

 route 10.200.0.0/24
  next-hop 10.0.0.2
 !
!
```

# use ncs_load to backup config for static-route service
```
student@nso-server:~$ ncs_load -M -F p -U -p /services/static-route -u student backup/static-route.xml
```

# Fuck up the static-route service
```
student@nso-server:~$ ncs_cli -C

User student last logged in 2024-09-24T17:55:06.768963+00:00, to nso-server, from 10.0.0.102 using cli-ssh
student connected from 10.0.0.102 using ssh on nso-server
student@ncs# config
Entering configuration mode terminal
student@ncs(config)# no services static-route
student@ncs(config)# commit no-networking 
Commit complete.
student@ncs(config)# 
student@ncs# show running-config services static-route 
% No entries found.
student@ncs# exit
```

# Load the previously backed up static-route.xml
```
student@nso-server:~$ ncs_load -l -m -j -M -U -n -u student backup/static-route.xml
```

# show running config after ncs_load 
```
student@ncs# show running-config services static-route
services static-route CE11
 route 10.100.0.0/24
  next-hop 10.0.0.1
 !
!
services static-route CE21
 route 10.200.0.0/24
  next-hop 10.0.0.2
 !
!
student@ncs# services check-sync 
sync-result {
    service-id /services/static-route:static-route[device='CE11']
    in-sync false
}
sync-result {
    service-id /services/static-route:static-route[device='CE21']
    in-sync false
}
```

# Re-deploy static-route service to devices
```
student@ncs# services static-route CE11 re-deploy no-networking 
student@ncs# 
System message at 2024-09-24 18:05:00...
Commit performed by student via ssh using cli.
student@ncs# services static-route CE21 re-deploy no-networking
student@ncs# 
System message at 2024-09-24 18:05:19...
Commit performed by student via ssh using cli.
```

# Validate service deployment
```
student@ncs# services check-sync 
sync-result {
    service-id /services/static-route:static-route[device='CE11']
    in-sync true
}
sync-result {
    service-id /services/static-route:static-route[device='CE21']
    in-sync true
}
student@ncs#
```