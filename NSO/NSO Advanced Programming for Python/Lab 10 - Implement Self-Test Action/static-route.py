# -*- mode: python; python-indent: 4 -*-
import ncs
from ncs.application import Service
import ipaddress
from ncs.dp import Action

class ServiceCallbacks(Service):

    @Service.create
    def cb_create(self, tctx, root, service, proplist):
        self.log.info(f"Service create(service='{service._path}')")

        for route in service.route:          
  
            # Convert CIDR to network address and netmask
            net = ipaddress.ip_network(route.ip_prefix)
            network_address = str(net.network_address)
            netmask = str(net.netmask)

            tvars = ncs.template.Variables()
            tvars.add('DEVICE', service.device)
            tvars.add('NETWORK-ADDRESS', network_address)
            tvars.add('NETMASK', netmask)
            tvars.add('NEXT-HOP', route.next_hop)
            tvars.add('IP-PREFIX', route.ip_prefix)

            template = ncs.template.Template(service)
            template.apply('static-route-template', tvars)

class SelfTest(Action):

    @Action.action
    def cb_action(self, uinfo, name, kp, action_input, action_output, trans):
        self.log.info(f"Action called: {name}")

        with ncs.maapi.single_read_trans('admin', 'python', db=ncs.OPERATIONAL) as t:
            root = ncs.maagic.get_root(t)
            route = ncs.maagic.get_node(t, kp)._parent
            service = route._parent._parent

            ping = root.devices.device[service.device].live_status.ios_stats__exec.ping
            ping_input = ping.get_input()
            ping_input.args = [route.next_hop]
            output = ping(ping_input)
            success = '!!!!!' in output.results
            if success:
                action_output.output = f"Next hop for route {route.ip_prefix} reachable."
            else:
                action_output.output = f"Next hop for route {route.ip_prefix} NOT reachable."

# ---------------------------------------------
# COMPONENT THREAD THAT WILL BE STARTED BY NCS.
# ---------------------------------------------
class StaticRoute(ncs.application.Application):
    def setup(self):
        self.log.info('StaticRoute RUNNING')
        self.register_service('static-route-servicepoint', ServiceCallbacks)
        self.register_action('self-test', SelfTest)

    def teardown(self):
        self.log.info('StaticRoute FINISHED')
