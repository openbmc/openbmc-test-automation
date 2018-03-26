#!/usr/bin/env python

r"""
Companion file to utils.robot.
"""

import gen_print as gp
import gen_robot_keyword as grk
import bmc_ssh_utils as bsu
import var_funcs as vf
from robot.libraries.BuiltIn import BuiltIn
from robot.libraries import DateTime
try:
    from robot.utils import DotDict
except ImportError:
    pass
import collections


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


def translate_power_policy_value(policy):
    r"""
    Translate the policy value and return the result.

    Using old style functions, callers might call like this with a hard-
    code value for policy:

    Set BMC Power Policy  ALWAYS_POWER_OFF

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


def get_bmc_date_time():
    r"""
    Get date/time info from BMC and return as a dictionary.

    Example of dictionary data returned by this keyword.
    time_dict:
      [local_time]:               Fri 2017-11-03 152756 UTC
      [local_time_seconds]:       1509740876
      [universal_time]:           Fri 2017-11-03 152756 UTC
      [universal_time_seconds]:   1509740876
      [rtc_time]:                 Fri 2016-05-20 163403
      [rtc_time_seconds]:         1463780043
      [time_zone]:                n/a (UTC, +0000)
      [network_time_on]:          yes
      [ntp_synchronized]:         no
      [rtc_in_local_tz]:          no
    """

    out_buf, stderr, rc = bsu.bmc_execute_command('timedatectl')
    # Example of output returned by call to timedatectl:
    #       Local time: Fri 2017-11-03 15:27:56 UTC
    #   Universal time: Fri 2017-11-03 15:27:56 UTC
    #         RTC time: Fri 2016-05-20 16:34:03
    #        Time zone: n/a (UTC, +0000)
    #  Network time on: yes
    # NTP synchronized: no
    #  RTC in local TZ: no

    # Convert the out_buf to a dictionary.
    initial_time_dict = vf.key_value_outbuf_to_dict(out_buf)

    # For each "_time" entry in the dictionary, we will create a corresponding
    # "_time_seconds" entry.  We create a new dictionary so that the entries
    # are kept in a nice order for printing.
    try:
        result_time_dict = collections.OrderedDict()
    except AttributeError:
        result_time_dict = DotDict()

    for key, value in initial_time_dict.items():
        result_time_dict[key] = value
        if not key.endswith("_time"):
            continue
        result_time_dict[key + '_seconds'] = \
            int(DateTime.convert_date(value, result_format='epoch'))

    return result_time_dict


def get_bmc_df(df_parm_string=""):
    r"""
    Get df report from BMC and return as a report "object".

    A df report object is a list where each entry is a dictionary whose keys
    are the field names from the first entry in report_list.

    Example df report object:

    df_report:
      df_report[0]:
        [filesystem]:    dev
        [1k-blocks]:     247120
        [used]:          0
        [available]:     247120
        [use%]:          0%
        [mounted]:       /dev
      df_report[1]:
        [filesystem]:    dev
        [1k-blocks]:     247120
        [used]:          0
        [available]:     247120
        [use%]:          0%
        [mounted]:       /dev

.   Description of argument(s):
    df_parm_string  A string containing valid df command parms (e.g.
                    "-h /var").
    """

    out_buf, stderr, rc = bsu.bmc_execute_command("df " + df_parm_string)
    return vf.outbuf_to_report(out_buf)


def get_sbe():
    r"""
    Return CFAM value which contains such things as SBE side bit.
    """

    cmd_buf = "pdbg -d p9w -p0 getcfam 0x2808 | sed -re 's/.* = //g'"
    out_buf, stderr, rc = bsu.bmc_execute_command(cmd_buf)

    return int(out_buf, 16)


def compare_mac_address(sys_mac_addr, user_mac_addr):
    r"""
    Return 1 if the MAC value matched, otherwise 0.

.   Description of argument(s):
    sys_mac_addr   A valid system MAC string (e.g. "70:e2:84:14:2a:08")
    user_mac_addr  A user provided MAC string (e.g. "70:e2:84:14:2a:08")
    """

    index = 0
    # Example: ['70', 'e2', '84', '14', '2a', '08']
    mac_list = user_mac_addr.split(":")
    for item in sys_mac_addr.split(":"):
        if int(item, 16) == int(mac_list[index], 16):
            index = index + 1
            continue
        return 0

    return 1
