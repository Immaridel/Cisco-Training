# -*- mode: python; python-indent: 4 -*-
import ncs
from . import nfvo_helpers
from .common import setup_crypto, authgroup_password

class VnfRequested(ncs.application.NanoService):
    @ncs.application.NanoService.create
    def cb_nano_create(self, tctx, root, service, plan, component, state, proplist, component_proplist):
        self.log.debug("NanoService create ", state)

        self.template = ncs.template.Template(service)
        vars = ncs.template.Variables()
        vars.add('USERNAME', tctx.username)

        setup_crypto(tctx)
        csr_pwd = authgroup_password(tctx, root, service.csr_authgroup)
        vars.add('CSR_PWD', csr_pwd)
        asa_pwd = authgroup_password(tctx, root, service.asa_authgroup)
        vars.add('ASA_PWD', asa_pwd)

        self.template.apply('deployment-request', vars)

class VnfCreated(ncs.application.NanoService):
    @ncs.application.NanoService.create
    def cb_nano_create(self, tctx, root, service, plan, component, state, proplist, component_proplist):
        self.log.debug("NanoService create ", state)

        ns_info_name = f"dmz-service-{service.name}"
        devices = nfvo_helpers.ns_devices(tctx, ns_info_name)
        self.log.info(f"devices = {devices}")

        device_name = devices[('CSR1kv', 'CSR')][0]
        self._set_operational_device_leaf(tctx, service, device_name, True)
        self.log.info(f"Router: CSR name {device_name}")
        template = ncs.template.Template(service.router)
        tvars = ncs.template.Variables()
        tvars.add('NAME', service.name)
        tvars.add('DEVICE', service.csr_name)
        template.apply('router-service-template', tvars)

        device_name = devices[('ASAv', 'ASA')][0]
        self._set_operational_device_leaf(tctx, service, device_name, False)
        self.log.info(f"FW: ASA name {device_name}")
        template = ncs.template.Template(service.firewall)
        tvars = ncs.template.Variables()
        tvars.add('NAME', service.name)
        tvars.add('DEVICE', service.asa_name)
        template.apply('firewall-service-template', tvars)

        self.log.info('Successfully configured DMZ service instance')

    def _set_operational_device_leaf(self, tctx, service, device_name, csr):
        with ncs.maapi.single_write_trans(tctx.username, tctx.context, db=ncs.OPERATIONAL) as oper_th:
            oper_service = ncs.maagic.get_node(oper_th, service._path)
            self.log.info(f"Writing device name leaf for {oper_service.csr_name}")
            if csr:
                oper_service.csr_name = device_name
            else:
                oper_service.asa_name = device_name
            oper_th.apply()

# ---------------------------------------------
# COMPONENT THREAD THAT WILL BE STARTED BY NCS.
# ---------------------------------------------
class DMZ(ncs.application.Application):

    def setup(self):
        self.log.info('DMZ RUNNING')
        self.register_nano_service('dmz-servicepoint', 'dmz:dmz', 'dmz:vnf-requested', VnfRequested)
        self.register_nano_service('dmz-servicepoint', 'dmz:dmz', 'dmz:vnf-created', VnfCreated)

    def teardown(self):
        self.log.info('DMZ FINISHED')