# Configure basic HA on Primray
```
student@nso-server:~/nso-ha$ make testenv-cli NSO=primary
docker exec -it testenv-nso-ha-6.1-student-nso-primary bash -lc 'ncs_cli -Cu admin'

User admin last logged in 2024-09-24T14:48:10.552391+00:00, to 48aa033bb5e3, from 127.0.0.1 using cli-console
admin connected from 127.0.0.1 using console on 48aa033bb5e3

admin@ncs-primary# config
Entering configuration mode terminal
admin@ncs-primary(config)# high-availability token NSO303
admin@ncs-primary(config)# high-availability settings enable-failover true
admin@ncs-primary(config)# high-availability settings start-up assume-nominal-role true
admin@ncs-primary(config)# high-availability settings start-up join-ha true
admin@ncs-primary(config)# high-availability settings reconnect-interval 2
admin@ncs-primary(config)# high-availability ha-node nso-primary address 172.21.0.2 nominal-role primary 
admin@ncs-primary(config-ha-node-nso-primary)# 
admin@ncs-primary(config)# high-availability ha-node nso-secondary address 172.21.0.3 nominal-role secondary failover-primary true
admin@ncs-primary(config-ha-node-nso-secondary)# top
admin@ncs-primary(config)# commit
Commit complete.
admin@ncs-primary(config)# high-availability enable
result enabled
admin@ncs-primary(config)# 
```

# Configure basic HA on Secondary
```
student@nso-server:~/nso-ha$ make testenv-cli NSO=secondary
docker exec -it testenv-nso-ha-6.1-student-nso-secondary bash -lc 'ncs_cli -Cu admin'

User admin last logged in 2024-09-24T14:48:05.964567+00:00, to 7d6e3ab82edb, from 127.0.0.1 using cli-console
admin connected from 127.0.0.1 using console on 7d6e3ab82edb
admin@ncs-secondary# config
Entering configuration mode terminal
admin@ncs-secondary(config)# high-availability token NSO303
admin@ncs-secondary(config)# high-availability ha-node nso-primary address 172.21.0.2 nominal-role primary
admin@ncs-secondary(config-ha-node-nso-primary)# 
admin@ncs-secondary(config)# high-availability ha-node nso-secondary address 172.21.0.3 nominal-role secondary
admin@ncs-secondary(config-ha-node-nso-secondary)# commit
Commit complete.
admin@ncs-secondary(config-ha-node-nso-secondary)# top
admin@ncs-secondary(config)# 
admin@ncs-secondary# high-availability enable 
result enabled
admin@ncs-secondary# high-availability be-secondary-to node nso-primary
result Attempting to be secondary to node nso-primary
admin@ncs-secondary# show high-availability 
high-availability enabled
high-availability status mode secondary
high-availability status current-id nso-secondary
high-availability status assigned-role secondary
high-availability status be-secondary-result initialized
high-availability status primary-id nso-primary
high-availability status read-only-mode false
admin@ncs-secondary# show running-config high-availability 
high-availability token $9$guvrbzLW4BuDCHhjIu3edVB3N9RKCOlwTKLEDQ0qauk=
high-availability ha-node nso-primary
 address      172.21.0.2
 nominal-role primary
!
high-availability ha-node nso-secondary
 address          172.21.0.3
 nominal-role     secondary
 failover-primary true
!
high-availability settings enable-failover true
high-availability settings start-up assume-nominal-role true
high-availability settings start-up join-ha true
high-availability settings reconnect-interval 2
admin@ncs-secondary#
```

# Check HA status on Primary
```
student@nso-server:~/nso-ha$ make testenv-cli NSO=primary
docker exec -it testenv-nso-ha-6.1-student-nso-primary bash -lc 'ncs_cli -Cu admin'

User admin last logged in 2024-09-24T14:48:29.21159+00:00, to 48aa033bb5e3, from 127.0.0.1 using cli-console
admin connected from 127.0.0.1 using console on 48aa033bb5e3
admin@ncs-primary# show high-availability status
high-availability status mode primary
high-availability status current-id nso-primary
high-availability status assigned-role primary
high-availability status read-only-mode false
ID             ADDRESS     
---------------------------
nso-secondary  172.21.0.3  

admin@ncs-primary#
```

# Test HA replication with customer
```
admin@ncs-primary# config
Entering configuration mode terminal
admin@ncs-primary(config)# customers customer ACME rank 1 status active 
admin@ncs-primary(config-customer-ACME)# commit
Commit complete.
```

# Display replicated customer status on Secondary
```
student@nso-server:~/nso-ha$ make testenv-cli NSO=secondary
docker exec -it testenv-nso-ha-6.1-student-nso-secondary bash -lc 'ncs_cli -Cu admin'

admin connected from 127.0.0.1 using console on 7d6e3ab82edb
admin@ncs-secondary# show running-config customers 
customers customer ACME
 rank   1
 status active
!
```

# Confirm Secondary cannot enter config mode
```
admin@ncs-secondary# config
Aborted: node is in read-only mode
```

# Configure HA VIP on Primary
```
student@nso-server:~/nso-ha$ make testenv-cli NSO=primary
docker exec -it testenv-nso-ha-6.1-student-nso-primary bash -lc 'ncs_cli -Cu admin'

User admin last logged in 2024-09-24T14:59:48.623682+00:00, to 48aa033bb5e3, from 127.0.0.1 using cli-console
admin connected from 127.0.0.1 using console on 48aa033bb5e3
admin@ncs-primary# config
Entering configuration mode terminal
admin@ncs-primary(config)# hcc enabled vip-address 192.168.0.100
admin@ncs-primary(config)# commit
Commit complete.
admin@ncs-primary(config)# 
admin@ncs-primary# 
student@nso-server:~/nso-ha$ 
```

# curl rquest example
```
student@nso-server:~/nso-ha$ curl -u admin:admin http://192.168.0.100/restconf -v
*   Trying 192.168.0.100:80...
* Connected to 192.168.0.100 (192.168.0.100) port 80 (#0)
* Server auth using Basic with user 'admin'
> GET /restconf HTTP/1.1
> Host: 192.168.0.100
> Authorization: Basic YWRtaW46YWRtaW4=
> User-Agent: curl/7.81.0
> Accept: */*
> 
* Mark bundle as not supporting multiuse
< HTTP/1.1 200 OK
< Date: Tue, 24 Sep 2024 15:06:42 GMT
< Cache-Control: private, no-cache, must-revalidate, proxy-revalidate
< Content-Length: 157
< Content-Type: application/yang-data+xml
< X-Cisco-NSO-Trace-ID: 5b88cbdc-cedc-4989-a2ce-e130e49e59d1
< Pragma: no-cache
< Content-Security-Policy: default-src 'self'; block-all-mixed-content; base-uri 'self'; frame-ancestors 'none';
< Strict-Transport-Security: max-age=15552000; includeSubDomains
< X-Content-Type-Options: nosniff
< X-Frame-Options: DENY
< X-XSS-Protection: 1; mode=block
< 
<restconf xmlns="urn:ietf:params:xml:ns:yang:ietf-restconf">
  <data/>
  <operations/>
  <yang-library-version>2019-01-04</yang-library-version>
</restconf>
* Connection #0 to host 192.168.0.100 left intact
```

# Stop the Primary to force failover
```
student@nso-server:~/nso-ha$ docker ps -a
CONTAINER ID   IMAGE                                        COMMAND             CREATED         STATUS                       PORTS                                                                                                             NAMES
7d6e3ab82edb   nso303.gitlab.local/nso-ha/nso:6.1-student   "/run-nso.sh"       7 months ago    Up About an hour (healthy)   22/tcp, 80/tcp, 443/tcp, 830/tcp, 4334/tcp                                                                        testenv-nso-ha-6.1-student-nso-secondary
48aa033bb5e3   nso303.gitlab.local/nso-ha/nso:6.1-student   "/run-nso.sh"       7 months ago    Up About an hour (healthy)   22/tcp, 80/tcp, 443/tcp, 830/tcp, 4334/tcp                                                                        testenv-nso-ha-6.1-student-nso-primary
5b243c1b17f3   gitlab/gitlab-ee:13.4.0-ee                   "/assets/wrapper"   11 months ago   Up About an hour (healthy)   0.0.0.0:80->80/tcp, :::80->80/tcp, 0.0.0.0:443->443/tcp, :::443->443/tcp, 0.0.0.0:8022->22/tcp, :::8022->22/tcp   gitlab_web_1
student@nso-server:~/nso-ha$ docker stop 48aa033bb5e3
48aa033bb5e3
student@nso-server:~/nso-ha$ make testenv-cli NSO=secondary
docker exec -it testenv-nso-ha-6.1-student-nso-secondary bash -lc 'ncs_cli -Cu admin'

admin connected from 127.0.0.1 using console on 7d6e3ab82edb
admin@ncs-secondary# show high-availability 
high-availability enabled
high-availability status mode none
high-availability status assigned-role secondary
high-availability status be-secondary-result "error (25) - could not connect to primary"
high-availability status primary-id nso-primary
high-availability status read-only-mode false
admin@ncs-secondary# *** ALARM ha-primary-down: Lost connection to primary due to: Primary closed connection
admin@ncs-secondary#
```

# Show alarms
```
admin@ncs-secondary# show alarms
alarms summary indeterminates 0
alarms summary criticals 1
alarms summary majors 0
alarms summary minors 0
alarms summary warnings 0
alarms alarm-list number-of-alarms 1
alarms alarm-list last-changed 2024-09-24T15:10:25.523132+00:00
alarms alarm-list alarm ncs ha-primary-down /high-availability/ha-node[id='nso-primary'] ""
 is-cleared              false
 last-status-change      2024-09-24T15:10:25.523132+00:00
 last-perceived-severity critical
 last-alarm-text         "Lost connection to primary due to: Primary closed connection"
 status-change 2024-09-24T15:10:25.523132+00:00
  received-time      2024-09-24T15:10:25.523132+00:00
  perceived-severity critical
  alarm-text         "Lost connection to primary due to: Primary closed connection"
```

# Check and start docker Primary container
```
student@nso-server:~/nso-ha$ curl -u admin:admin http://192.168.0.100/restconf
<restconf xmlns="urn:ietf:params:xml:ns:yang:ietf-restconf">
  <data/>
  <operations/>
  <yang-library-version>2019-01-04</yang-library-version>
</restconf>
student@nso-server:~/nso-ha$ docker ps -a
CONTAINER ID   IMAGE                                        COMMAND             CREATED         STATUS                       PORTS                                                                                                             NAMES
7d6e3ab82edb   nso303.gitlab.local/nso-ha/nso:6.1-student   "/run-nso.sh"       7 months ago    Up About an hour (healthy)   22/tcp, 80/tcp, 443/tcp, 830/tcp, 4334/tcp                                                                        testenv-nso-ha-6.1-student-nso-secondary
48aa033bb5e3   nso303.gitlab.local/nso-ha/nso:6.1-student   "/run-nso.sh"       7 months ago    Exited (143) 8 minutes ago                                                                                                                     testenv-nso-ha-6.1-student-nso-primary
5b243c1b17f3   gitlab/gitlab-ee:13.4.0-ee                   "/assets/wrapper"   11 months ago   Up About an hour (healthy)   0.0.0.0:80->80/tcp, :::80->80/tcp, 0.0.0.0:443->443/tcp, :::443->443/tcp, 0.0.0.0:8022->22/tcp, :::8022->22/tcp   gitlab_web_1
student@nso-server:~/nso-ha$ docker start 48aa033bb5e3
48aa033bb5e3
```

# Check HA status on Primary
```
student@nso-server:~/nso-ha$ make testenv-cli NSO=primary
docker exec -it testenv-nso-ha-6.1-student-nso-primary bash -lc 'ncs_cli -Cu admin'

admin connected from 127.0.0.1 using console on 48aa033bb5e3
admin@ncs-primary# show high-availability  
high-availability enabled
high-availability status mode secondary
high-availability status current-id nso-primary
high-availability status assigned-role secondary
high-availability status be-secondary-result initialized
high-availability status primary-id nso-secondary
high-availability status read-only-mode false
admin@ncs-primary#
```

# Set Primary back to HA Primary
```
admin@ncs-primary# high-availability be-primary 
result ok
admin@ncs-primary# 
```

# Set Secondary back to HA Secondary
```
student@nso-server:~/nso-ha$ make testenv-cli NSO=secondary
docker exec -it testenv-nso-ha-6.1-student-nso-secondary bash -lc 'ncs_cli -Cu admin'

admin connected from 127.0.0.1 using console on 7d6e3ab82edb

admin@ncs-secondary# high-availability be-secondary-to node nso-primary 
result Attempting to be secondary to node nso-primary
admin@ncs-secondary# show high-availability status
high-availability status mode secondary
high-availability status current-id nso-secondary
high-availability status assigned-role secondary
high-availability status be-secondary-result initialized
high-availability status primary-id nso-primary
high-availability status read-only-mode false
admin@ncs-secondary#
```