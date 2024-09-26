# Notes?
I'm not sure which lab had me run this, but I left it for posterity.

```
admin@ncs# devices migrate device [ CE40 ] old-ned-id cisco-ios-cli-6.21 new-ned-id cisco-ios-cli-6.85 verbose dry-run | begin flow-export | more          
admin@ncs# show running-config devices device CE40 config ip flow-export | display xml | display service-meta-data 
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
