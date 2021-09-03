#!/usr/bin/env python3

r"""
This module contains functions for tftp update.
"""

from robot.libraries.BuiltIn import BuiltIn

import state as st
import gen_print as gp


def get_pre_reboot_state():
    r"""
    Get and return a custom state which is comprised of the
    st.default_req_states plus epoch_seconds.
    """

    global state

    req_states = ['epoch_seconds'] + st.default_req_states

    gp.qprint_timen("Get system state.")
    state = st.get_state(req_states=req_states, quiet=0)
    gp.qprint_var(state)
    return state


def wait_for_reboot(start_boot_seconds):
    r"""
    Wait for the BMC to complete a previously initiated reboot.

    Description of argument(s):
    start_boot_seconds  The time that the boot test started.  The format is the
                        epoch time in seconds, i.e. the number of seconds since
                        1970-01-01 00:00:00 UTC.  This value should be obtained
                        from the BMC so that it is not dependent on any kind of
                        synchronization between this machine and the target BMC
                        This will allow this program to work correctly even in
                        a simulated environment.  This value should be obtained
                        by the caller prior to initiating a reboot.  It can be
                        obtained as follows:
                        state = st.get_state(req_states=['epoch_seconds'])

    """

    st.wait_for_comm_cycle(int(start_boot_seconds))

    gp.qprintn()
    st.wait_state(st.standby_match_state, wait_time="10 mins", interval="10 seconds")
