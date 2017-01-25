#!/usr/bin/env python

r"""
State Manager module:

   - Defines Valid states of the system

"""
from robot.libraries.BuiltIn import BuiltIn

BuiltIn().import_resource("state_manager.robot")

# We will build eventually the mapping for warm, cold rest as well.
VALID_STATES = {
    'reboot':
    {
         # (BMC state, Chassis State, Host State)
         ('Ready','Off','Off'),
         ('Ready','On','Running'),
    },
}


class state_map():

    def get_system_states(self):
        r"""
        #######################################################################
        #   @brief    Method returns BMC, Chassis and Host state.
        #   @return   State tuple.
        #######################################################################
        """
        l_bmc_state = BuiltIn().run_keyword('Get BMC State')
        l_chassis_state = BuiltIn().run_keyword('Get Chassis Power State')
        l_host_state = BuiltIn().run_keyword('Get Host State')
        return (l_bmc_state, l_chassis_state, l_host_state)

    def is_valid_states(self, i_type, i_state_tuple):
        r"""
        #######################################################################
        #   @brief    Method check if given tuple state is valid.
        #   @param    i_type: @type string: Reset type
        #   @param    i_state_tuple: @type list: States(bmc,chassis,host)
        #   @return   Booolean True is Valid else False.
        #######################################################################
        """
        try:
            if i_state_tuple in set(VALID_STATES[i_type]):
                return True
            else:
                return False
        except KeyError:
            return False
