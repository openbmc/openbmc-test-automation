#!/usr/bin/env python

r"""
Companion file to utils.robot.
"""

import gen_print as gp
import gen_robot_keyword as grk
from robot.libraries.BuiltIn import BuiltIn


###############################################################################
def set_power_policy_method():

    r"""
    Set the global bmc_power_policy_method to either 'Old' or 'New'.

    The power policy data has moved from an 'org' location to an 'xyz'
    location.  This keyword will determine whether the new method of getting
    the power policy is valid and will set the global bmc_power_policy_method
    variable accordingly.  If power_policy_setup is already set (by a prior
    call to this function), this keyword will simply return.

    If bmc_power_policy_method is "Old", this function will adjust the global
    policy variables from data/variables.py: RESTORE_LAST_STATE,
    ALWAYS_POWER_ON, ALWAYS_POWER_OFF.
    """

    # Retrieve global variables.
    power_policy_setup = \
        int(BuiltIn().get_variable_value("${power_policy_setup}",
                                         default=0))
    bmc_power_policy_method = \
        BuiltIn().get_variable_value("${bmc_power_policy_method}",
                                     default=0)
    gp.dpvar(power_policy_setup)

    # If this function has already been run once, we need not continue.
    if power_policy_setup:
        return

    gp.dpvar(bmc_power_policy_method, 1)

    # The user has not set bmc_power_policy_method via a -v parm so we will
    # determine what it should be.
    if bmc_power_policy_method == "":
        status, ret_values = grk.run_key_u("New Get Power Policy", ignore=1)
        if status == 'PASS':
            bmc_power_policy_method = 'New'
        else:
            bmc_power_policy_method = 'Old'

    gp.qpvar(bmc_power_policy_method)
    # For old style, we will rewrite these global variable settings to old
    # values.
    if bmc_power_policy_method == "Old":
        BuiltIn().set_global_variable("${RESTORE_LAST_STATE}",
                                      "RESTORE_LAST_STATE")
        BuiltIn().set_global_variable("${ALWAYS_POWER_ON}",
                                      "ALWAYS_POWER_ON")
        BuiltIn().set_global_variable("${ALWAYS_POWER_OFF}",
                                      "ALWAYS_POWER_OFF")

    # Set global variables to control subsequent calls to this function.
    BuiltIn().set_global_variable("${bmc_power_policy_method}",
                                  bmc_power_policy_method)
    BuiltIn().set_global_variable("${power_policy_setup}", 1)


###############################################################################


###############################################################################
def translate_power_policy_value(policy):

    r"""
    Translate the policy value and return the result.

    Using old style functions, callers might call like this with a hard-
    code value for policy:

    Set BMC Power Policy  RESTORE_LAST_STATE

    This function will get the value of the corresponding global variable (if
    it exists) and return it.

    This will allow the old style call to still work on systems using the new
    method of storing the policy value.
    """

    valid_power_policy_vars = \
        BuiltIn().get_variable_value("${valid_power_policy_vars}")

    if policy not in valid_power_policy_vars:
        return policy

    status, ret_values = grk.run_key_u("Get Variable Value  ${" + policy + "}",
                                       quiet=1)
    return ret_values

###############################################################################
