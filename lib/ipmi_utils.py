#!/usr/bin/env python

r"""
Provide useful ipmi functions.
"""

import gen_print as gp
import gen_misc as gm
import gen_robot_keyword as grk
import gen_robot_utils as gru
import bmc_ssh_utils as bsu
import var_funcs as vf
import tempfile
gru.my_import_resource("ipmi_client.robot")
from robot.libraries.BuiltIn import BuiltIn


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


def get_lan_print_dict():

    r"""
    Get IPMI 'lan print' output and return it as a dictionary.

    Here is an example of the IPMI lan print output:

    Set in Progress         : Set Complete
    Auth Type Support       : MD5 
    Auth Type Enable        : Callback : MD5 
                            : User     : MD5 
                            : Operator : MD5 
                            : Admin    : MD5 
                            : OEM      : MD5 
    IP Address Source       : Static Address
    IP Address              : 9.41.165.233
    Subnet Mask             : 255.255.252.0
    MAC Address             : 70:e2:84:14:24:a6
    Default Gateway IP      : 9.41.164.1
    802.1q VLAN ID          : Disabled
    Cipher Suite Priv Max   : Not Available
    Bad Password Threshold  : Not Available

    Given that data, this function will return the following dictionary.

    lan_print_dict:
      [Set in Progress]:                              Set Complete
      [Auth Type Support]:                            MD5
      [Auth Type Enable]:
        [Callback]:                                   MD5
        [User]:                                       MD5
        [Operator]:                                   MD5
        [Admin]:                                      MD5
        [OEM]:                                        MD5
      [IP Address Source]:                            Static Address
      [IP Address]:                                   9.41.165.233
      [Subnet Mask]:                                  255.255.252.0
      [MAC Address]:                                  70e2841424a6
      [Default Gateway IP]:                           9.41.164.1
      [802.1q VLAN ID]:                               Disabled
      [Cipher Suite Priv Max]:                        Not Available
      [Bad Password Threshold]:                       Not Available

    """

    IPMI_INBAND_CMD = BuiltIn().get_variable_value("${IPMI_INBAND_CMD}")

    # Notice in the example of data above that 'Auth Type Enable' needs some
    # special processing.  We essentially want to isolate its data and remove
    # the 'Auth Type Enable' string so that key_value_outbuf_to_dict can
    # process it as a sub-dictionary.
    cmd_buf = IPMI_INBAND_CMD + " lan print | grep -E '^(Auth Type Enable)" +\
        "?[ ]+: ' | sed -re 's/^(Auth Type Enable)?[ ]+: //g'"
    stdout1, stderr, rc = bsu.os_execute_command(cmd_buf)

    # Now get the remainder of the data and exclude the lines with no field
    # names (i.e. the 'Auth Type Enable' sub-fields).
    cmd_buf = IPMI_INBAND_CMD + " lan print | grep -E -v '^[ ]+: '"
    stdout2, stderr, rc = bsu.os_execute_command(cmd_buf)

    # Make auth_type_enable_dict sub-dictionary...
    auth_type_enable_dict = vf.key_value_outbuf_to_dict(stdout1, to_lower=0,
                                                        underscores=0)

    # Create the lan_print_dict...
    lan_print_dict = vf.key_value_outbuf_to_dict(stdout2, to_lower=0,
                                                 underscores=0)
    # Re-assign 'Auth Type Enable' to contain the auth_type_enable_dict.
    lan_print_dict['Auth Type Enable'] = auth_type_enable_dict

    return lan_print_dict
