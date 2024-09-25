## make service RFS package
student@nso-server:~/nso-lsa/nso-rfs$ make dev-shell
docker run -it -v $(pwd):/src nso303.gitlab.local/cisco-nso-dev:6.1
root@ee649c8a76b1:/# cd src/packages/
root@ee649c8a76b1:/src/packages# ncs-make-package --service-skeleton python-and-template l3vpn-rfs
root@ee649c8a76b1:/src/packages# chown -Rv 1000:1000 l3vpn-rfs/
changed ownership of 'l3vpn-rfs/test/internal/lux/service/dummy-service.xml' from root:root to 1000:1000
changed ownership of 'l3vpn-rfs/test/internal/lux/service/pyvm.xml' from root:root to 1000:1000
changed ownership of 'l3vpn-rfs/test/internal/lux/service/dummy-device.xml' from root:root to 1000:1000
changed ownership of 'l3vpn-rfs/test/internal/lux/service/run.lux' from root:root to 1000:1000
changed ownership of 'l3vpn-rfs/test/internal/lux/service/Makefile' from root:root to 1000:1000
changed ownership of 'l3vpn-rfs/test/internal/lux/service' from root:root to 1000:1000
changed ownership of 'l3vpn-rfs/test/internal/lux/Makefile' from root:root to 1000:1000
changed ownership of 'l3vpn-rfs/test/internal/lux' from root:root to 1000:1000
changed ownership of 'l3vpn-rfs/test/internal/Makefile' from root:root to 1000:1000
changed ownership of 'l3vpn-rfs/test/internal' from root:root to 1000:1000
changed ownership of 'l3vpn-rfs/test/Makefile' from root:root to 1000:1000
changed ownership of 'l3vpn-rfs/test' from root:root to 1000:1000
changed ownership of 'l3vpn-rfs/README' from root:root to 1000:1000
changed ownership of 'l3vpn-rfs/templates/l3vpn-rfs-template.xml' from root:root to 1000:1000
changed ownership of 'l3vpn-rfs/templates' from root:root to 1000:1000
changed ownership of 'l3vpn-rfs/package-meta-data.xml' from root:root to 1000:1000
changed ownership of 'l3vpn-rfs/python/l3vpn_rfs/main.py' from root:root to 1000:1000
changed ownership of 'l3vpn-rfs/python/l3vpn_rfs/__init__.py' from root:root to 1000:1000
changed ownership of 'l3vpn-rfs/python/l3vpn_rfs' from root:root to 1000:1000
changed ownership of 'l3vpn-rfs/python' from root:root to 1000:1000
changed ownership of 'l3vpn-rfs/src/yang/l3vpn-rfs.yang' from root:root to 1000:1000
changed ownership of 'l3vpn-rfs/src/yang' from root:root to 1000:1000
changed ownership of 'l3vpn-rfs/src/Makefile' from root:root to 1000:1000
changed ownership of 'l3vpn-rfs/src' from root:root to 1000:1000
changed ownership of 'l3vpn-rfs/' from root:root to 1000:1000
root@ee649c8a76b1:/src/packages# logout
student@nso-server:~/nso-lsa/nso-rfs$

# Replace empty yang model with Monolithic service original yang file
student@nso-server:~/nso-lsa/nso-rfs$ cp -r ~/packages/l3vpn/src/yang/l3vpn.yang packages/l3vpn-rfs/src/yang/l3vpn-rfs.yang

# Rename l3vpn to l3vpn-rfs
vim packages/l3vpn-rfs/src/yang/l3vpn-rfs.yang
    run ':%s/l3vpn/l3vpn-rfs/g'

# Copy Template and main.py from old Monolithic service to new RFS service
student@nso-server:~/nso-lsa/nso-rfs$ cp ~/packages/l3vpn/templates/l3vpn-template.xml packages/l3vpn-rfs/templates/l3vpn-rfs-template.xml 
student@nso-server:~/nso-lsa/nso-rfs$ cp ~/packages/l3vpn/python/l3vpn/main.py packages/l3vpn-rfs/python/l3vpn_rfs/main.py 

# Rename l3vpn to l3vpn-rfs
vim packages/l3vpn-rfs/python/l3vpn_rfs/main.py
    run ':%s/l3vpn/l3vpn-rfs/g'

# Build
student@nso-server:~/nso-lsa/nso-rfs$ make testenv-build 
for NSO in $(docker ps --format '{{.Names}}' --filter label=testenv-nso-rfs-6.1-student --filter label=nidtype=nso); do \
	echo "-- Rebuilding for NSO: ${NSO}"; \
	docker run -it --rm -v /home/student/nso-lsa/nso-rfs:/src --volumes-from ${NSO} --network=container:${NSO} -e NSO=${NSO} -e PACKAGE_RELOAD= -e SKIP_LINT= -e PKG_FILE=nso303.gitlab.local/nso-rfs/package:6.1-student nso303.gitlab.local/cisco-nso-dev:6.1 /src/nid/testenv-build; \
done
-- Rebuilding for NSO: testenv-nso-rfs-6.1-student-nso-emea
(package-meta-data.xml|\.cli1|\.yang1)
make: Entering directory '/var/opt/ncs/packages/cisco-ios-cli-6.85/src'
mkdir -p \
    artefacts \
    ncsc-out/modules \
    tmp-yang \
    ../load-dir
mkdir -p \
    ../private-jar \
    ../shared-jar \
    java/src/com/tailf/packages/ned/ios/namespaces
cp yang/*.yang  tmp-yang

======== CREATE ../package-meta-data.xml and ../load-dir/tailf-ned-id-cisco-ios-cli-6.85.fxs
rm -f ../package-meta-data.xml
---
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
    package l3vpn-rfs
    result true
}

## Make cfs NED
student@nso-server:~/nso-lsa/nso-rfs$ cp -r packages/l3vpn-rfs/ ../nso-cfs/packages/
student@nso-server:~/nso-lsa/nso-rfs$ cd ../nso-cfs/
student@nso-server:~/nso-lsa/nso-cfs$ make dev-shell
docker run -it -v $(pwd):/src nso303.gitlab.local/cisco-nso-dev:6.1
root@22693904da06:/# cd src/packages/
root@22693904da06:/src/packages# ncs-make-package --lsa-netconf-ned l3vpn-rfs/src/yang/ l3vpn-rfs-ned
root@22693904da06:/src/packages# rm -rf l3vpn-rfs
root@22693904da06:/src/packages# logout
student@nso-server:~/nso-lsa/nso-cfs$ sudo vim packages/l3vpn-rfs-ned/src/yang/l3vpn-rfs.yang 

    # change 'leaf device' stanza to a string

      leaf device {
        tailf:info "Device";
        type string;
      }

student@nso-server:~/nso-lsa/nso-cfs$ make testenv-build 
for NSO in $(docker ps --format '{{.Names}}' --filter label=testenv-nso-cfs-6.1-student --filter label=nidtype=nso); do \
	echo "-- Rebuilding for NSO: ${NSO}"; \
	docker run -it --rm -v /home/student/nso-lsa/nso-cfs:/src --volumes-from ${NSO} --network=container:${NSO} -e NSO=${NSO} -e PACKAGE_RELOAD= -e SKIP_LINT= -e PKG_FILE=nso303.gitlab.local/nso-cfs/package:6.1-student nso303.gitlab.local/cisco-nso-dev:6.1 /src/nid/testenv-build; \
done
-- Rebuilding for NSO: testenv-nso-cfs-6.1-student-nso
---
>>> System upgrade is starting.
>>> Sessions in configure mode must exit to operational mode.
>>> No configuration changes can be performed until upgrade has completed.
>>> System upgrade has completed successfully.
reload-result {
    package l3vpn-rfs-ned
    result true
}

## Create l3vpn-cfs Package
student@nso-server:~/nso-lsa/nso-cfs$ make dev-shell
docker run -it -v $(pwd):/src nso303.gitlab.local/cisco-nso-dev:6.1
root@e59870190e92:/# cd src/packages/
root@e59870190e92:/src/packages# ncs-make-package --service-skeleton python-and-template l3vpn-cfs
root@e59870190e92:/src/packages# chown -Rv 1000:1000 l3vpn-cfs/
changed ownership of 'l3vpn-cfs/test/internal/lux/service/dummy-service.xml' from root:root to 1000:1000
changed ownership of 'l3vpn-cfs/test/internal/lux/service/pyvm.xml' from root:root to 1000:1000
changed ownership of 'l3vpn-cfs/test/internal/lux/service/dummy-device.xml' from root:root to 1000:1000
changed ownership of 'l3vpn-cfs/test/internal/lux/service/run.lux' from root:root to 1000:1000
changed ownership of 'l3vpn-cfs/test/internal/lux/service/Makefile' from root:root to 1000:1000
changed ownership of 'l3vpn-cfs/test/internal/lux/service' from root:root to 1000:1000
changed ownership of 'l3vpn-cfs/test/internal/lux/Makefile' from root:root to 1000:1000
changed ownership of 'l3vpn-cfs/test/internal/lux' from root:root to 1000:1000
changed ownership of 'l3vpn-cfs/test/internal/Makefile' from root:root to 1000:1000
changed ownership of 'l3vpn-cfs/test/internal' from root:root to 1000:1000
changed ownership of 'l3vpn-cfs/test/Makefile' from root:root to 1000:1000
changed ownership of 'l3vpn-cfs/test' from root:root to 1000:1000
changed ownership of 'l3vpn-cfs/README' from root:root to 1000:1000
changed ownership of 'l3vpn-cfs/templates/l3vpn-cfs-template.xml' from root:root to 1000:1000
changed ownership of 'l3vpn-cfs/templates' from root:root to 1000:1000
changed ownership of 'l3vpn-cfs/package-meta-data.xml' from root:root to 1000:1000
changed ownership of 'l3vpn-cfs/python/l3vpn_cfs/main.py' from root:root to 1000:1000
changed ownership of 'l3vpn-cfs/python/l3vpn_cfs/__init__.py' from root:root to 1000:1000
changed ownership of 'l3vpn-cfs/python/l3vpn_cfs' from root:root to 1000:1000
changed ownership of 'l3vpn-cfs/python' from root:root to 1000:1000
changed ownership of 'l3vpn-cfs/src/yang/l3vpn-cfs.yang' from root:root to 1000:1000
changed ownership of 'l3vpn-cfs/src/yang' from root:root to 1000:1000
changed ownership of 'l3vpn-cfs/src/Makefile' from root:root to 1000:1000
changed ownership of 'l3vpn-cfs/src' from root:root to 1000:1000
changed ownership of 'l3vpn-cfs/' from root:root to 1000:1000
root@e59870190e92:/src/packages#


# vim packages/l3vpn-cfs/python/l3vpn_cfs/main.py
:%s/l3vpn/l3vpn-cfs/g

# Copy Template to CFS Service directory
student@nso-server:~/nso-lsa/nso-cfs$ cat packages/l3vpn-cfs/templates/l3vpn-cfs-template.xml 
<config-template xmlns="http://tail-f.com/ns/config/1.0">
  <devices xmlns="http://tail-f.com/ns/ncs">
    <device>
      <!--
          Select the devices from some data structure in the service
          model. In this skeleton the devices are specified in a leaf-list.
          Select all devices in that leaf-list:
      -->
      <name>{/device}</name>
      <config>
        <!--
            Add device-specific parameters here.
            In this skeleton the, java code sets a variable DUMMY, use it
            to set something on the device e.g.:
            <ip-address-on-device>{$DUMMY}</ip-address-on-device>
        -->
      </config>
    </device>
  </devices>
</config-template>

student@nso-server:~/nso-lsa/nso-cfs$ cp -r ~/packages/l3vpn-cfs/templates/l3vpn-cfs-template.xml packages/l3vpn-cfs/templates/l3vpn-cfs-template.xml

student@nso-server:~/nso-lsa/nso-cfs$ cat packages/l3vpn-cfs/templates/l3vpn-cfs-template.xml 
<config-template xmlns="http://tail-f.com/ns/config/1.0">
  <devices xmlns="http://tail-f.com/ns/ncs">
    <device>
      <name>{$RFS-NODE}</name>
      <config>
        <l3vpn-rfs xmlns="http://cisco.com/example/l3vpn-rfs">
          <vpn-name>{string(../vpn-name)}</vpn-name>
          <link>
            <id>{$ID}</id>
            <device>{$DEVICE}</device>
            <interface>{$INTERFACE}</interface>
            <ip-address>{$IP-ADDRESS}</ip-address>
            <mask>{$MASK}</mask>
          </link>
        </l3vpn-rfs>
      </config>
    </device>
  </devices>
</config-template>

student@nso-server:~/nso-lsa/nso-cfs$ cp ~/packages/l3vpn-cfs/python/l3vpn_cfs/main.py packages/l3vpn-cfs/python/l3vpn_cfs/main.py 
student@nso-server:~/nso-lsa/nso-cfs$ vim packages/l3vpn-cfs/python/l3vpn_cfs/main.py
student@nso-server:~/nso-lsa/nso-cfs$ make testenv-build 
for NSO in $(docker ps --format '{{.Names}}' --filter label=testenv-nso-cfs-6.1-student --filter label=nidtype=nso); do \
	echo "-- Rebuilding for NSO: ${NSO}"; \
	docker run -it --rm -v /home/student/nso-lsa/nso-cfs:/src --volumes-from ${NSO} --network=container:${NSO} -e NSO=${NSO} -e PACKAGE_RELOAD= -e SKIP_LINT= -e PKG_FILE=nso303.gitlab.local/nso-cfs/package:6.1-student nso303.gitlab.local/cisco-nso-dev:6.1 /src/nid/testenv-build; \
done
-- Rebuilding for NSO: testenv-nso-cfs-6.1-student-nso
(package-meta-data.xml|\.cli1|\.yang1)
make: Entering directory '/var/opt/ncs/packages/l3vpn-rfs-ned/src'
cd java && ant -q all

BUILD SUCCESSFUL
---
>>> System upgrade is starting.
>>> Sessions in configure mode must exit to operational mode.
>>> No configuration changes can be performed until upgrade has completed.
>>> System upgrade has completed successfully.
reload-result {
    package l3vpn-cfs
    result true
}
reload-result {
    package l3vpn-rfs-ned
    result true
}