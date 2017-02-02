#!/usr/bin/env python

r"""
This module is the python counterpart to utils.robot.  It provides many
functions for communicating with the Open BMC machine.
"""

import gen_robot_print as grp
import state as state_mod
import gen_robot_utils as gru

from robot.libraries.BuiltIn import BuiltIn

# We need utils.robot to get keyword "Initiate Power On".
gru.my_import_resource("utils.robot")


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

    state_change_timeout = BuiltIn().get_variable_value(
        "${STATE_CHANGE_TIMEOUT}", default="1 min")

    # Wait for the state to change in any way.
    state_mod.wait_state(match_state, wait_time=state_change_timeout,
                         interval="3 seconds", invert=1)

    if state_mod.OBMC_STATES_VERSION == 0:
        cmd_buf = ["Create Dictionary", "power=${1}",
                   "bmc=HOST_BOOTED",
                   "boot_progress=FW Progress, Starting OS"]
    else:
        cmd_buf = ["Create Dictionary", "chassis=On",
                   "bmc=HOST_BOOTED",
                   "boot_progress=FW Progress, Starting OS",
                   "host=Running"]
    grp.rdpissuing_keyword(cmd_buf)
    final_state = BuiltIn().run_keyword(*cmd_buf)

    os_host = BuiltIn().get_variable_value("${OS_HOST}", default="")

    if os_host != "":
        final_state['os_ping'] = 1
        final_state['os_login'] = 1
        final_state['os_run_cmd'] = 1

    final_state = state_mod.anchor_state(final_state)

    grp.rprintn()
    power_on_timeout = BuiltIn().get_variable_value(
        "${POWER_ON_TIMEOUT}", default="14 mins")
    state_mod.wait_state(final_state, wait_time=power_on_timeout,
                         interval="3 seconds")

###############################################################################
