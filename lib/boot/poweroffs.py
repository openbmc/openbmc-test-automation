#!/usr/bin/env python

r"""
This module is the python counterpart to poweroffs.robot.  It provides
functions for powering off an open bmc machine.
"""

import gen_robot_print as grp
import state as state_mod
import gen_robot_utils as gru

from robot.libraries.BuiltIn import BuiltIn

# We need utils.robot to get keyword "Initiate Power Off".
gru.my_import_resource("utils.robot")


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

    state_change_timeout = BuiltIn().get_variable_value(
        "${STATE_CHANGE_TIMEOUT}", default="1 min")

    # Wait for the state to change in any way.
    state_mod.wait_state(match_state, wait_time=state_change_timeout,
                         interval="3 seconds", invert=1)

    if state_mod.OBMC_STATES_VERSION == 0:
        cmd_buf = ["Create Dictionary", "power=${0}",
                   "bmc=HOST_POWERED_OFF", "boot_progress=Off"]
    else:
        cmd_buf = ["Create Dictionary", "chassis=Off",
                   "bmc=HOST_POWERED_OFF", "boot_progress=Off",
                   "host=Off"]
    grp.rdpissuing_keyword(cmd_buf)
    final_state = BuiltIn().run_keyword(*cmd_buf)

    final_state = state_mod.anchor_state(final_state)

    grp.rprintn()
    power_off_timeout = BuiltIn().get_variable_value(
        "${POWER_OFF_TIMEOUT}", default="2 mins")
    state_mod.wait_state(final_state, wait_time=power_off_timeout,
                         interval="3 seconds")

###############################################################################
