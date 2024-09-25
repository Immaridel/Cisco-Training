# -*- made: python; python-indent: 4 -*-
import ncs
import _ncs

class Upgrade(ncs.upgrade.Upgrade):
    def upgrade(self, cdbsock, trans):
        _ncs.cdb.start_session2(cdbsock, ncs.cdb.RUNNING, ncs.cdb.LOCK_SESSION | ncs.cdb.LOCK_WAIT)
        num = _ncs.cdb.num_instances(cdbsock, "/l3mplsvpn")

        for i in range(0, num):
            name = str(_ncs.cdb.get(cdbsock, f"/l3mplsvpn[{i}]/name"))
            customer = str(_ncs.cdb.get(cdbsock, f"/l3mplsvpn[{i}]/customer"))
            description = "VPN for " + customer
            trans.set_elem(description, f"/l3mplsvpn{{{name}}}/description")
        return True