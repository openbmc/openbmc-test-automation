#!/usr/bin/env python

r"""
This module contains functions for tftp update.

"""

from robot.libraries.BuiltIn import BuiltIn

import state as st
import gen_print as gp

match_state = {
    "rest": "^1$",
    "bmc": "^Ready$",
    "rest": "^1$",
    "chassis": "^Off$",
    "boot_progress": "^Unspecified$",
    "operating_system": "^Inactive$",
    "host": "^Off$"
},


def get_current_state():
    r"""
    Get the system state.
    """

    global state

    req_states = ['epoch_seconds'] + st.default_req_states

    gp.qprint_timen("Get system state.")
    state = st.get_state(req_states=req_states, quiet=0)
    gp.qprint_var(state)


def wait_for_bmc_standby():
    r"""
    Wait for BMC to reach standby
    """

    st.wait_for_comm_cycle(int(state['epoch_seconds']))

    gp.qprintn()
    st.wait_state(match_state[0], wait_time="10 mins", interval="10 seconds")
