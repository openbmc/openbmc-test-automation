#!/usr/bin/env python

r"""
Provide useful ipmi functions.
"""

import gen_misc as gm
import gen_robot_keyword as grk
import gen_robot_utils as gru
import tempfile
gru.my_import_resource("ipmi_client.robot")


def get_sol_info():

    r"""
    Get all SOL info and return it as a dictionary.

    Example use:

    Robot code:
    ${sol_info}=  get_sol_info
    Rpvars  sol_info

    Output:
    sol_info:
      sol_info[Info]:                                SOL parameter 'Payload Channel (7)' not supported - defaulting to 0x0e
      sol_info[Character Send Threshold]:            1
      sol_info[Force Authentication]:                true
      sol_info[Privilege Level]:                     USER
      sol_info[Set in progress]:                     set-complete
      sol_info[Retry Interval (ms)]:                 100
      sol_info[Non-Volatile Bit Rate (kbps)]:        IPMI-Over-Serial-Setting
      sol_info[Character Accumulate Level (ms)]:     100
      sol_info[Enabled]:                             true
      sol_info[Volatile Bit Rate (kbps)]:            IPMI-Over-Serial-Setting
      sol_info[Payload Channel]:                     14 (0x0e)
      sol_info[Payload Port]:                        623
      sol_info[Force Encryption]:                    true
      sol_info[Retry Count]:                         7
    """

    status, ret_values = grk.run_key_u("Run IPMI Standard Command  sol info")

    # Create temp file path.
    temp = tempfile.NamedTemporaryFile()
    temp_file_path = temp.name

    # Write sol info to temp file path.
    text_file = open(temp_file_path, "w")
    text_file.write(ret_values)
    text_file.close()

    # Use my_parm_file to interpret data.
    sol_info = gm.my_parm_file(temp_file_path)

    return sol_info


def set_sol_setting(setting_name, setting_value):

    r"""
    Set SOL setting with given value.

    # Description of argument(s):
    # setting_name    SOL setting which needs to be set (e.g. "retry-count").
    # setting_value   Value which needs to be set (e.g. "7").
    """

    status, ret_values = grk.run_key_u("Run IPMI Standard Command  sol set " +
                                       setting_name + " " + setting_value)

    return status


