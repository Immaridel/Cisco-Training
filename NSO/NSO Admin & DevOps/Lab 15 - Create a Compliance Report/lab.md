# Create compliance report definition
```
student@nso-server:~$ ncs_cli -C

student connected from 10.0.0.102 using ssh on nso-server
student@ncs# config
Entering configuration mode terminal

student@ncs(config)# devices device-group PE_Routers
student@ncs(config-device-group-PE_Routers)# device-name [ PE11 PE22 ]
student@ncs(config-device-group-PE_Routers)# top
student@ncs(config)# compliance reports report System_Report
student@ncs(config-report-System_Report)# device-check device-group PE_Routers
student@ncs(config-report-System_Report)# device-check current-out-of-sync true
student@ncs(config-report-System_Report)# device-check historic-changes true
student@ncs(config-report-System_Report)# device-check historic-out-of-sync true
student@ncs(config-report-System_Report)# service-check all-services 
student@ncs(config-report-System_Report)# service-check current-out-of-sync true
student@ncs(config-report-System_Report)# service-check historic-out-of-sync true
student@ncs(config-report-System_Report)# commit
Commit complete.
student@ncs(config-report-System_Report)# top
student@ncs(config)#
```

# Generate HTML compliance report
```
student@ncs# compliance reports report System_Report run outformat html
time 2024-09-26T13:34:37.737322+00:00
compliance-status violations
info Checking 2 devices and no services
location http://localhost:8080/compliance-reports/report_2024-09-26T13:34:37.737322+00:00.html
```
### Change the address from 'localhost' to 'nso-server'
http://nso-server:8080/compliance-reports/report_2024-09-26T13:34:37.737322+00:00.html

# Create device template called DNS_Config to use against PE_Routers
```
student@ncs# config
Entering configuration mode terminal
student@ncs(config)# devices template DNS_Config
student@ncs(config-template-DNS_Config)# ned-id cisco-iosxr-cli-7.41 
student@ncs(config-ned-id-cisco-iosxr-cli-7.41)# config
student@ncs(config-config)# domain name-server 10.0.0.50
student@ncs(config-name-server-10.0.0.50)# exit
student@ncs(config-config)# domain name-server 10.0.0.51
student@ncs(config-name-server-10.0.0.51)# top
student@ncs(config)# commit
Commit complete.
student@ncs(config)# top
```

# Create compliance report called DNS_Configuration against template DNS_Config
```
student@ncs(config)# compliance reports report DNS_Configuration
student@ncs(config-report-DNS_Configuration)# compare-template DNS_Config PE_Routers
student@ncs(config-compare-template-DNS_Config/PE_Routers)# top
student@ncs(config)# commit
Commit complete.
student@ncs(config)# exit
student@ncs# compliance reports report DNS_Configuration run outformat html
time 2024-09-26T13:46:11.887238+00:00
compliance-status violations
info Checking no devices and no services
location http://localhost:8080/compliance-reports/report_2024-09-26T13:46:11.887238+00:00.html
```
### Change the address from 'localhost' to 'nso-server'
http://nso-server:8080/compliance-reports/report_2024-09-26T13:46:11.887238+00:00.html
