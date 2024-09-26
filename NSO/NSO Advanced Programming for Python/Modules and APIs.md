show python-vm
    Python 3.4+ supported (unsure of nso version)

Low-Level Modules:
_ncs
    _ncs.maapi - Restful API
    _ncs.dp - Southound data provider (device configs)
    _ncs.cdb - Read-Only Configuration Data, Write options for operational data only
    _ncs.error - error access
    _ncs.events - event logging access
    _ncs.ha - HA API calls


High-level APIs (for python)
- REST and RESTCONF APIs
- ncs module - ncs Python high-level module (supports above submodules)
- NCS Modules & Submodules
    ncs.maapi - Management Agent API (Read & Write config data)
        Config data read will be commited AND uncommited data in-flight (pre-commit)
    ncs.maagic - CDB Navigation
    ncs.application - Fastmap service access
    ncs.template - Fastmap service access
    ncs.log
    ncs.experimental
    ncs.dp - Data Provider API: Service callbacks, hooks, and transforms
    ncs.cdb - Read-Only Configuration Data, Write options for operational data only
        Config data read is only commited data.  No pre-commit, in-flight data is seen.  Use MAAPI.
    ncs.error
    ncs.events
    ncs.ha


