#!/usr/bin/env python

r"""
This module is the python counterpart to poweroffs.robot.  It provides
functions for powering off an open bmc machine.
"""

import gen_robot_print as grp
import state as state_mod

from robot.libraries.BuiltIn import BuiltIn

# We need utils.robot to get keyword "Initiate Power Off".
BuiltIn().import_resource("utils.robot")


###############################################################################
def bmc_power_off():

    r"""
    Power the Open BMC machine off and monitor status to verify.
    """

    grp.rprint_timen("Refreshing state data.")
    state = state_mod.get_state()
    grp.rprint_var(state)

    match_state = state_mod.anchor_state(state)

    grp.rprintn()
    cmd_buf = ["Initiate Power Off"]
    grp.rpissuing_keyword(cmd_buf)
    power = BuiltIn().run_keyword(*cmd_buf)

    # Wait for the state to change in any way.
    state_mod.wait_state(match_state, wait_time="1 min", interval="3 seconds",
                         invert=1)

    cmd_buf = ["Create Dictionary", "power=${0}",
               "bmc=HOST_POWERED_OFF", "boot_progress=Off"]
    grp.rdpissuing_keyword(cmd_buf)
    final_state = BuiltIn().run_keyword(*cmd_buf)

    final_state = state_mod.anchor_state(final_state)

    grp.rprintn()
    state_mod.wait_state(final_state, wait_time="2 min", interval="3 seconds")

###############################################################################
