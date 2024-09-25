# -*- mode: python; python-indent: 4 -*-
import ncs
from ncs.application import Service

class ServiceCallbacks(Service):

    # The create() callback is invoked inside NCS FASTMAP and must always exist.
    @Service.create
    def cb_create(self, tctx, root, service, proplist):
        self.log.info(f'Service create(service={service._path})')

        if service.router.exists():
            self.log.info('Router config exists, will create Router instance')
            template = ncs.template.Template(service.router)
            tvars = ncs.template.Variables()
            tvars.add('NAME', service.name)
            tvars.add('DEVICE', service.csr_name)
            template.apply('router-service-template', tvars)

        if service.firewall.exists():
            self.log.info('Firewall service exists, will create Firewall instance')
            template = ncs.template.Template(service.firewall)
            tvars = ncs.template.Variables()
            tvars.add('NAME', service.name)
            tvars.add('DEVICE', service.asa_name)
            template.apply('firewall-service-template', tvars)

# ---------------------------------------------
# COMPONENT THREAD THAT WILL BE STARTED BY NCS.
# ---------------------------------------------
class DMZ(ncs.application.Application):

    def setup(self):
        self.log.info('DMZ RUNNING')
        self.register_service('dmz-servicepoint', ServiceCallbacks)

    def teardown(self):
        self.log.info('DMZ FINISHED')
