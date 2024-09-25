# Add oper linux user//groups
student@nso-server:~$ sudo useradd oper
student@nso-server:~$ sudo passwd oper
New password: 
BAD PASSWORD: The password is shorter than 8 characters
Retype new password: 
passwd: password updated successfully
student@nso-server:~$ sudo usermod -aG ncsoper oper

# Validate running config
student@nso-server:~$ ncs_cli -C
User student last logged in 2024-09-23T17:23:18.334874+00:00, to nso-server, from 10.0.0.102 using cli-ssh
student connected from 10.0.0.102 using ssh on nso-server
student@ncs# show running-config nacm groups
nacm groups group ncsadmin
 user-name [ private ]
!
nacm groups group ncsoper
 user-name [ public ]
!

# Add allow-create-update-on-device NACM rule
student@ncs# config
Entering configuration mode terminal
student@ncs(config)# nacm rule-list oper rule allow-create-update-on-device path /devices access-operations create,update action permit
student@ncs(config-rule-allow-create-update-on-device)# top
student@ncs(config)# commit dry-run
cli {
    local-node {
        data  nacm {
                  rule-list oper {
             +        # after rule read-only
             +        rule allow-create-update-on-device {
             +            path /devices;
             +            access-operations create,update;
             +            action permit;
             +        }
                  }
              }
    }
}

# Add allow-l3vpn NACM rule
student@ncs(config)# nacm rule-list oper rule allow-l3vpn path /services/l3vpn access-operations create,update,delete action permit
student@ncs(config-rule-allow-l3vpn)# top
student@ncs(config)# commit
Commit complete.
student@ncs(config)# 
student@ncs# 

# Add check-sync//sync-to NACM rule
student@nso-server:~$ ncs_cli -C

User student last logged in 2024-09-23T17:43:06.399237+00:00, to nso-server, from 10.0.0.102 using cli-ssh
student connected from 10.0.0.102 using ssh on nso-server
student@ncs# config
Entering configuration mode terminal
student@ncs(config)# nacm rule-list oper rule allow-check-syn 
Possible completions:
  access-operations  action  comment  context  log-if-permit  module-name  notification-name  path  rpc-name  <cr>
student@ncs(config)# nacm rule-list oper rule allow-check-sync path /devices/device/check-sync access-operations exec action permit
student@ncs(config-rule-allow-check-sync)# top                                                                                               student@ncs(config)# nacm rule-list oper rule allow-sync-to path /devices/device/sync-to access-operations exec action permit      
student@ncs(config-rule-allow-sync-to)# top
student@ncs(config)# commit
Commit complete.
student@ncs(config)# 
student@ncs# 

# Add monitor linux user//groups
student@nso-server:~$ sudo useradd monitor
student@nso-server:~$ sudo passwd monitor
New password: 
BAD PASSWORD: The password contains the user name in some form
Retype new password: 
passwd: password updated successfully
student@nso-server:~$ sudo groupadd ncsmonitor
student@nso-server:~$ sudo usermod -aG ncsmonitor monitor

# add monitor to ncsmonitor group in NSO
student@nso-server:~$ ncs_cli -C
User student last logged in 2024-09-23T17:58:09.735576+00:00, to nso-server, from 10.0.0.102 using cli-ssh
student connected from 10.0.0.102 using ssh on nso-server
student@ncs# config
Entering configuration mode terminal
student@ncs(config)# nacm groups group ncsmonitor
student@ncs(config-group-ncsmonitor)# top
student@ncs(config)# commit
Commit complete.
student@ncs(config)# exit
student@ncs# exit

# Validate monitor privs
student@nso-server:~$ ssh monitor@127.0.0.1 -p 2024
monitor connected from 127.0.0.1 using ssh on nso-server
monitor@ncs> ?
Possible completions:
  exit - Exit the management session
  quit - Exit the management session
monitor@ncs>

# Add permit-l3vpn and cmdrule NACM rules
student@ncs# config
Entering configuration mode terminal
student@ncs(config)# nacm rule-list monitor group ncsmonitor rule permit-l3vpn-read access-operations read path /service/l3vpn action permit
student@ncs(config-rule-permit-l3vpn-read)# top
student@ncs(config)# 
student@ncs(config)# nacm rule-list monitor cmdrule any-command action permit
student@ncs(config-cmdrule-any-command)# top
student@ncs(config)# commit
Commit complete.
student@ncs(config)#

# Check monitor user's nacm rule-list
student@nso-server:~$ ncs_cli -C

User student last logged in 2024-09-23T18:12:23.358876+00:00, to nso-server, from 10.0.0.102 using cli-ssh
student connected from 10.0.0.102 using ssh on nso-server
student@ncs# show running-config nacm rule-list monitor
nacm rule-list monitor
 group [ ncsmonitor ]
 rule permit-l3vpn-read
  path              /service/l3vpn
  access-operations read
  action            permit
 !
 cmdrule any-command
  action permit
 !
!
