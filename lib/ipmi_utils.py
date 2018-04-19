#!/usr/bin/env python

r"""
Provide useful ipmi functions.
"""

import re
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
    IP Address              : x.x.x.x
    Subnet Mask             : x.x.x.x
    MAC Address             : xx:xx:xx:xx:xx:xx
    Default Gateway IP      : x.x.x.x
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
      [IP Address]:                                   x.x.x.x
      [Subnet Mask]:                                  x.x.x.x
      [MAC Address]:                                  xx:xx:xx:xx:xx:xx
      [Default Gateway IP]:                           x.x.x.x
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


def get_ipmi_power_reading(strip_watts=1):
    r"""
    Get IPMI power reading data and return it as a dictionary.

    The data is obtained by issuing the IPMI "power reading" command.  An
    example is shown below:

    Instantaneous power reading:                   234 Watts
    Minimum during sampling period:                234 Watts
    Maximum during sampling period:                234 Watts
    Average power reading over sample period:      234 Watts
    IPMI timestamp:                           Thu Jan  1 00:00:00 1970
    Sampling period:                          00000000 Seconds.
    Power reading state is:                   deactivated

    For the data shown above, the following dictionary will be returned.

    result:
      [instantaneous_power_reading]:              238 Watts
      [minimum_during_sampling_period]:           238 Watts
      [maximum_during_sampling_period]:           238 Watts
      [average_power_reading_over_sample_period]: 238 Watts
      [ipmi_timestamp]:                           Thu Jan  1 00:00:00 1970
      [sampling_period]:                          00000000 Seconds.
      [power_reading_state_is]:                   deactivated

    Description of argument(s):
    strip_watts  Strip all dictionary values of the trailing " Watts"
                 substring.
    """

    status, ret_values = \
        grk.run_key_u("Run IPMI Standard Command  dcmi power reading")
    result = vf.key_value_outbuf_to_dict(ret_values)

    if strip_watts:
        result.update((k, re.sub(' Watts$', '', v)) for k, v in result.items())

    return result


def get_mc_info():
    r"""
    Get IPMI mc info data and return it as a dictionary.

    The data is obtained by issuing the IPMI "mc info" command.  An
    example is shown below:

    Device ID                 : 0
    Device Revision           : 0
    Firmware Revision         : 2.01
    IPMI Version              : 2.0
    Manufacturer ID           : 42817
    Manufacturer Name         : Unknown (0xA741)
    Product ID                : 16975 (0x424f)
    Product Name              : Unknown (0x424F)
    Device Available          : yes
    Provides Device SDRs      : yes
    Additional Device Support :
        Sensor Device
        SEL Device
        FRU Inventory Device
        Chassis Device
    Aux Firmware Rev Info     :
        0x00
        0x00
        0x00
        0x00

    For the data shown above, the following dictionary will be returned.
    mc_info:
      [device_id]:                       0
      [device_revision]:                 0
      [firmware_revision]:               2.01
      [ipmi_version]:                    2.0
      [manufacturer_id]:                 42817
      [manufacturer_name]:               Unknown (0xA741)
      [product_id]:                      16975 (0x424f)
      [product_name]:                    Unknown (0x424F)
      [device_available]:                yes
      [provides_device_sdrs]:            yes
      [additional_device_support]:
        [additional_device_support][0]:  Sensor Device
        [additional_device_support][1]:  SEL Device
        [additional_device_support][2]:  FRU Inventory Device
        [additional_device_support][3]:  Chassis Device
      [aux_firmware_rev_info]:
        [aux_firmware_rev_info][0]:      0x00
        [aux_firmware_rev_info][1]:      0x00
        [aux_firmware_rev_info][2]:      0x00
        [aux_firmware_rev_info][3]:      0x00
    """

    status, ret_values = \
        grk.run_key_u("Run IPMI Standard Command  mc info")
    result = vf.key_value_outbuf_to_dict(ret_values, process_indent=1)

    return result


def get_sdr_info():
    r"""
    Get IPMI sdr info data and return it as a dictionary.

    The data is obtained by issuing the IPMI "sdr info" command.  An
    example is shown below:

    SDR Version                         : 0x51
    Record Count                        : 216
    Free Space                          : unspecified
    Most recent Addition                :
    Most recent Erase                   :
    SDR overflow                        : no
    SDR Repository Update Support       : unspecified
    Delete SDR supported                : no
    Partial Add SDR supported           : no
    Reserve SDR repository supported    : no
    SDR Repository Alloc info supported : no

    For the data shown above, the following dictionary will be returned.
    mc_info:

      [sdr_version]:                         0x51
      [record_Count]:                        216
      [free_space]:                          unspecified
      [most_recent_addition]:
      [most_recent_erase]:
      [sdr_overflow]:                        no
      [sdr_repository_update_support]:       unspecified
      [delete_sdr_supported]:                no
      [partial_add_sdr_supported]:           no
      [reserve_sdr_repository_supported]:    no
      [sdr_repository_alloc_info_supported]: no
    """

    status, ret_values = \
        grk.run_key_u("Run IPMI Standard Command  sdr info")
    result = vf.key_value_outbuf_to_dict(ret_values, process_indent=1)

    return result


def get_aux_version(version_id):
    r"""
    Get IPMI Aux version info data and return it.

    Description of argument(s):
    version_id    The data is obtained by from BMC /etc/os-release
                  (e.g. "xxx-v2.1-438-g0030304-r3-gfea8585").

    Example is shown below:
    Aux Firmware Rev Info BCD format displayed from IPMI mc info o/p:
        0x04
        0x38
        0x00
        0x03

    Aux version return from this function 4380003.
    """

    # Commit version.
    count = re.findall("-(\d{1,4})-", version_id)

    # Release version.
    release = re.findall("-r(\d{1,4})", version_id)
    if release:
        aux_version = count[0] + "{0:0>4}".format(release[0])
    else:
        aux_version = count[0] + "0000"

    return aux_version
