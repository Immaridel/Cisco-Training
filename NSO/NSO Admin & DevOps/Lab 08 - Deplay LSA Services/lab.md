# Add EMEA and AM RFS devices
### Modify ssh-algorithms to add 'ssh-dss' support for older devices
### add ssh-rsa ssh-dss
```
student@nso-server:~/nso-lsa/nso-cfs$ make testenv-cli
docker exec -it testenv-nso-cfs-6.1-student-nso bash -lc 'ncs_cli -Cu admin'

User admin last logged in 2024-09-24T17:06:38.943803+00:00, to 2c96826b35f3, from 127.0.0.1 using cli-console
admin connected from 127.0.0.1 using console on 2c96826b35f3
admin@ncs# config
Entering configuration mode terminal
admin@ncs(config)# devices global-settings ssh-algorithms public-key 
[list] (ssh-ed25519 ecdsa-sha2-nistp256 ecdsa-sha2-nistp384 ecdsa-sha2-nistp521 rsa-sha2-512 rsa-sha2-256): 
admin@ncs(config)# devices global-settings ssh-algorithms public-key [ ssh-ed25519 ecdsa-sha2-nistp256 ecdsa-sha2-nistp384 ecdsa-sha2-nistp521 rsa-sha2-512 rsa-sha2-256 ssh-rsa ssh-dss ]
admin@ncs(config)# devices device NSO-RFS-AM address NSO-RFS-AM port 830 authgroup lsa device-type netconf ned-id lsa-netconf 
admin@ncs(config-device-NSO-RFS-AM)# state admin-state unlocked 
admin@ncs(config-device-NSO-RFS-AM)# top
admin@ncs(config)# devices device NSO-RFS-EMEA address NSO-RFS-EMEA port 830 authgroup lsa device-type netconf ned-id lsa-netconf 
admin@ncs(config-device-NSO-RFS-EMEA)# state admin-state unlocked
admin@ncs(config-device-NSO-RFS-EMEA)# top
admin@ncs(config)# commit
Commit complete.
admin@ncs(config)# 
```

# Fetch Keys & dispatch-map
```
admin@ncs# devices fetch-ssh-host-keys
fetch-result {
    device NSO-RFS-AM
    result updated
    fingerprint {
        algorithm ssh-rsa
        value 31:37:ea:af:c2:93:17:36:fa:57:97:b9:b9:1c:51:16
    }
}
fetch-result {
    device NSO-RFS-EMEA
    result updated
    fingerprint {
        algorithm ssh-rsa
        value 5a:3a:68:8c:24:27:36:60:79:5b:c6:72:25:32:79:5e
    }
}
admin@ncs# devices sync-from
sync-result {
    device NSO-RFS-AM
    result true
}
sync-result {
    device NSO-RFS-EMEA
    result true
}
admin@ncs# config
Entering configuration mode terminal
admin@ncs(config)# dispatch-map AMNSO-RFS-AM
admin@ncs(config)# dispatch-map EMEA NSO-RFS-EMEA
admin@ncs(config)# commit
Commit complete.
```

# Configure dispatch-map and create VPN using template
```
admin@ncs# config
Entering configuration mode terminal
admin@ncs(config)# dispatch-map AM NSO-RFS-AM    
admin@ncs(config)# dispatch-map EMEA NSO-RFS-EMEA
admin@ncs(config)# commit
Commit complete.
admin@ncs(config)# l3vpn-cfs vpn1 link CustomerA device CE11-AM interface 0/1 ip-address 10.100.0.1 mask 255.255.255.255
admin@ncs(config-link-CustomerA)# commit
admin@ncs(config-link-CustomerA)# top                                                 
admin@ncs(config)# l3vpn-cfs vpn1 link CustomerB device CE21-EMEA interface 0/1 ip-address 10.200.0.1 mask 255.255.255.255
admin@ncs(config-link-CustomerB)# commit

admin@ncs(config-link-CustomerB)# top
admin@ncs(config)# 
admin@ncs# 
student@nso-server:~/nso-lsa/nso-cfs$ cd ../nso-rfs/
student@nso-server:~/nso-lsa/nso-rfs$ make testenv-cli NSO=am
docker exec -it testenv-nso-rfs-6.1-student-nso-am bash -lc 'ncs_cli -Cu admin'
```

# Validate created BGP configuration
```
User admin last logged in 2024-09-24T17:37:03.087558+00:00, to 2a6444447ec3, from 172.21.0.2 using netconf-ssh
admin connected from 127.0.0.1 using console on 2a6444447ec3
admin@ncs-am# show running-config devices device CE11-AM config router bgp
devices device CE11-AM
 config
  router bgp 65000
   address-family ipv4 unicast vrf vpn1
    neighbor 10.100.0.1 remote-as 65001
    exit-address-family
   !
  !
 !
!
admin@ncs-am#
```

# SSH device and confirm running configuration
```
student@nso-server:~/nso-lsa/nso-rfs$ make testenv-shell NSO=am
docker exec -it testenv-nso-rfs-6.1-student-nso-am bash -l
root@2a6444447ec3:/# ssh admin@CE11-AM
The authenticity of host 'ce11-am (172.21.0.5)' can't be established.
ED25519 key fingerprint is SHA256:wW/jaiD6hClI+E7EGhK5fXkSwOmPTsS4P71UK6LQb8s.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added 'ce11-am,172.21.0.5' (ED25519) to the list of known hosts.
admin@ce11-am's password: 

User admin last logged in 2024-09-24T17:37:03.977007+00:00, to 425540fd1c4a, from 172.21.0.3 using cli-ssh
admin connected from 172.21.0.3 using ssh on 425540fd1c4a
dev> enable
dev# show running-config router bgp
router bgp 65000
 address-family ipv4 unicast vrf vpn1
  neighbor 10.100.0.1 remote-as 65001
  exit-address-family
 !
!
dev# 
dev# exit
Connection to ce11-am closed.
root@2a6444447ec3:/# logout
```