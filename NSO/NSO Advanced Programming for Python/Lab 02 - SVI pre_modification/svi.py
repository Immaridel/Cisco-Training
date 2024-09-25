# -*- mode: python; python-indent: 4 -*-
import ncs
from ncs.application import Service
import ipaddress



# ------------------------
# SERVICE CALLBACK EXAMPLE
# ------------------------
class ServiceCallbacks(Service):

    @Service.create
    def cb_create(self, tctx, root, service, proplist):
        self.log.info(f'Service create(service={service._path})')
        svi = {'vlan-id': "",
               'svi-device': "",
               'ip-prefix': "",
               'ip-addr': "",
               'netmask': ""}
        #debugpy.breakpoint()

        # proplist object list(tuple(str,str)) to pass information between invocations. We set
        # value for vlan_id in cb_pre_modification and use it here in cb_create.
        svi['vlan-id'] = [x[1] for x in proplist if x[0] == 'vlan-id'][0]


        for device in service.device:
            self.log.info(f'Entering /device list = {device.name}')
            if device.ip_prefix:
                self.log.info(f'SVI device = {device.name}')

                ip_net = ipaddress.ip_network(device.ip_prefix)
                svi['svi-device'] = device.name
                svi['ip-prefix'] = f'{ip_net[2]}/{ip_net.prefixlen}'
                svi['ip-addr'] = str(ip_net[1])
                svi['netmask'] = str(ip_net.netmask)

                svi_tvars = ncs.template.Variables()
                svi_tvars.add('VLAN-ID', svi['vlan-id'])
                svi_tvars.add('SVI-DEVICE', svi['svi-device'])
                svi_tvars.add('IP-PREFIX', svi['ip-prefix'])
                svi_tvars.add('IP-ADDR', svi['ip-addr'])
                svi_tvars.add('NETMASK', svi['netmask'])
                svi_template = ncs.template.Template(service)
                svi_template.apply('svi-intf-template', svi_tvars)

        vlan_tvars = ncs.template.Variables()
        vlan_tvars.add('VLAN-ID', svi['vlan-id'])
        vlan_template = ncs.template.Template(service)
        vlan_template.apply('svi-vlan-template', vlan_tvars)

    @Service.pre_modification
    def cb_pre_modification(self, tctx, op, kp, root, proplist):
        self.log.info(f'Service premod(service={kp})')
        if op == ncs.dp.NCS_SERVICE_CREATE:
            self.log.info('Service premod(operation=NCS_SERVICE_CREATE, allocate)')
            vlan_id = root.services.vlan_id_cnt
            proplist.append(('vlan-id', str(vlan_id)))
            self.log.info(f'Service premod(allocated vlan-id: {vlan_id})')
            root.services.vlan_id_cnt = vlan_id + 1

        elif op == ncs.dp.NCS_SERVICE_DELETE:
            self.log.info('Service premod(operation=NCS_SERVICE_DELETE, skip)')

        return proplist

# ---------------------------------------------
# COMPONENT THREAD THAT WILL BE STARTED BY NCS.
# ---------------------------------------------
class Svi(ncs.application.Application):
    def setup(self):
        self.log.info('Main RUNNING')
        self.register_service('svi-servicepoint', ServiceCallbacks)
    def teardown(self):
        self.log.info('Main FINISHED')
