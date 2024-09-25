# -*- mode: python; python-indent: 4 -*-
import ncs
from ncs.application import Service

class ServiceCallbacks(Service):

    # The create() callback is invoked inside NCS FASTMAP and
    # must always exist.
    @Service.create
    def cb_create(self, tctx, root, service, proplist):
        self.log.info(f'Service create(service={service._path})')

        device = service.device

        for rule in service.access_list_rules:
            template = ncs.template.Template(service)
            tvars = ncs.template.Variables()

            tvars.add('DEVICE', device)
            tvars.add('ACCESS-LIST-NAME', rule.name)
            tvars.add('INTERFACE-ID', rule.interface.string)
            tvars.add('ACCESS-LIST-DIRECTION', rule.direction.string)

            tvars.add('ACCESS-LIST-RULE', self._build_acl_rule(rule))
            template.apply('firewall-template', tvars)

    def _build_acl_rule(self, rule):
        action = rule.action.string
        protocol = rule.protocol
        src_ip = rule.src_ip
        src_mask = rule.src_mask
        src_port = self._stringify_port(rule.src_port)
        dest_ip = rule.dest_ip
        dest_mask = rule.dest_mask
        dest_port = self._stringify_port(rule.dest_port)
        acl_entry = f'extended {action} {protocol} {src_ip} {src_mask} {src_port} {dest_ip} {dest_mask} {dest_port}'
            
        self.log.info(f'Generated ACL entry: {acl_entry}')

        return acl_entry.rstrip()

    def _stringify_port(self,port):
        if isinstance(port, int):
            return f'eq {port}' 
        else:
            return ''

# ---------------------------------------------
# COMPONENT THREAD THAT WILL BE STARTED BY NCS.
# ---------------------------------------------
class Firewall(ncs.application.Application):
    def setup(self):
        self.log.info('Firewall RUNNING')
        self.register_service('firewall-servicepoint', ServiceCallbacks)

    def teardown(self):
        self.log.info('Firewall FINISHED')
