#!/usr/bin/env python

r"""
State Manager module:

   - Defines Valid states of the system

"""
from robot.libraries.BuiltIn import BuiltIn

BuiltIn().import_resource("state_manager.robot")

# We will build eventually the mapping for warm, cold reset as well.
VALID_STATES = {
    'reboot':
    {
         # (BMC state, Chassis State, Host State)
         ('Ready','Off','Off'),
         ('Ready','On','Running'),
    },
}


class state_map():

    def get_system_state(self):
        r"""
        Return the system state as a tuple of bmc, chassis and host states.
        """
        bmc_state = BuiltIn().run_keyword('Get BMC State')
        chassis_state = BuiltIn().run_keyword('Get Chassis Power State')
        host_state = BuiltIn().run_keyword('Get Host State')
        return (bmc_state, chassis_state, host_state)

    def valid_boot_state(self, boot_type, state_set):
        r"""
        Validate a given set of states is valid.

        Description of arguments:
        boot_type   Reset type (reboot/warm/cold)
        state_set   State set (bmc,chassis,host)
        """
        if state_set in set(VALID_STATES[boot_type]):
            return True
        else:
            return False
