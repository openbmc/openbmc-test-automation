#!/usr/bin/env python

r"""
This module is the python counterpart to utils.robot.  It provides many
functions for communicating with the Open BMC machine.
"""

import gen_robot_print as grp
import state as state_mod

from robot.libraries.BuiltIn import BuiltIn

# We need utils.robot to get keyword "Initiate Power On".
BuiltIn().import_resource("utils.robot")


###############################################################################
def bmc_power_on():

    r"""
    Power the Open BMC machine on and monitor status to verify.
    """

    grp.rprint_timen("Refreshing state data.")
    state = state_mod.get_state()
    grp.rprint_var(state)

    match_state = state_mod.anchor_state(state)

    grp.rprintn()
    cmd_buf = ["Initiate Power On", "wait=${0}"]
    grp.rpissuing_keyword(cmd_buf)
    power = BuiltIn().run_keyword(*cmd_buf)

    # Wait for the state to change in any way.
    state_mod.wait_state(match_state, wait_time="1 min", interval="3 seconds",
                         invert=1)

    cmd_buf = ["Create Dictionary", "power=${1}",
               "bmc=HOST_BOOTED",
               "boot_progress=FW Progress, Starting OS"]
    grp.rdpissuing_keyword(cmd_buf)
    final_state = BuiltIn().run_keyword(*cmd_buf)

    try:
        os_host = BuiltIn().get_variable_value("${OS_HOST}")
    except TypeError:
        os_host = ""

    if os_host != "":
        final_state['os_ping'] = 1
        final_state['os_login'] = 1
        final_state['os_run_cmd'] = 1

    final_state = state_mod.anchor_state(final_state)

    grp.rprintn()
    state_mod.wait_state(final_state, wait_time="14 mins",
                         interval="3 seconds")

###############################################################################
