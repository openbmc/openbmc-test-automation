#!/usr/bin/env python3

r"""
Companion file to utils.robot.
"""

import collections
import json
import os

import bmc_ssh_utils as bsu
import gen_print as gp
import gen_robot_keyword as grk
import var_funcs as vf
from robot.libraries import DateTime
from robot.libraries.BuiltIn import BuiltIn

try:
    from robot.utils import DotDict
except ImportError:
    pass
import re

# The code base directory will be one level up from the directory containing this module.
code_base_dir_path = os.path.dirname(os.path.dirname(__file__)) + os.sep


def get_code_base_dir_path():
    r"""
    Return the dir path of our code base.
    """

    return code_base_dir_path


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
    power_policy_setup = int(
        BuiltIn().get_variable_value("${power_policy_setup}", default=0)
    )
    bmc_power_policy_method = BuiltIn().get_variable_value(
        "${bmc_power_policy_method}", default=0
    )
    gp.dpvar(power_policy_setup)

    # If this function has already been run once, we need not continue.
    if power_policy_setup:
        return

    gp.dpvar(bmc_power_policy_method, 1)

    # The user has not set bmc_power_policy_method via a -v parm so we will
    # determine what it should be.
    if bmc_power_policy_method == "":
        status, ret_values = grk.run_key_u("New Get Power Policy", ignore=1)
        if status == "PASS":
            bmc_power_policy_method = "New"
        else:
            bmc_power_policy_method = "Old"

    gp.qpvar(bmc_power_policy_method)
    # For old style, we will rewrite these global variable settings to old
    # values.
    if bmc_power_policy_method == "Old":
        BuiltIn().set_global_variable(
            "${RESTORE_LAST_STATE}", "RESTORE_LAST_STATE"
        )
        BuiltIn().set_global_variable("${ALWAYS_POWER_ON}", "ALWAYS_POWER_ON")
        BuiltIn().set_global_variable(
            "${ALWAYS_POWER_OFF}", "ALWAYS_POWER_OFF"
        )

    # Set global variables to control subsequent calls to this function.
    BuiltIn().set_global_variable(
        "${bmc_power_policy_method}", bmc_power_policy_method
    )
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

    valid_power_policy_vars = BuiltIn().get_variable_value(
        "${valid_power_policy_vars}"
    )

    if policy not in valid_power_policy_vars:
        return policy

    status, ret_values = grk.run_key_u(
        "Get Variable Value  ${" + policy + "}", quiet=1
    )
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

    out_buf, stderr, rc = bsu.bmc_execute_command("timedatectl")
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
        result_time_dict[key + "_seconds"] = int(
            DateTime.convert_date(value, result_format="epoch")
        )

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


def get_os_ethtool(interface_name):
    r"""
    Get OS 'ethtool' output for the given interface_name and return it as a
    dictionary.

    Settings for enP52p1s0f0:
          Supported ports: [ TP ]
          Supported link modes:   10baseT/Half 10baseT/Full
                                  100baseT/Half 100baseT/Full
                                  1000baseT/Half 1000baseT/Full
          Supported pause frame use: No
          Supports auto-negotiation: Yes
          Supported FEC modes: Not reported
          Advertised link modes:  10baseT/Half 10baseT/Full
                                  100baseT/Half 100baseT/Full
                                  1000baseT/Half 1000baseT/Full
          Advertised pause frame use: Symmetric
          Advertised auto-negotiation: Yes
          Advertised FEC modes: Not reported
          Speed: Unknown!
          Duplex: Unknown! (255)
          Port: Twisted Pair
          PHYAD: 1
          Transceiver: internal
          Auto-negotiation: on
          MDI-X: Unknown
          Supports Wake-on: g
          Wake-on: g
          Current message level: 0x000000ff (255)
                                 drv probe link timer ifdown ifup rx_err tx_err
          Link detected: no

    Given that data, this function will return the following dictionary.

    ethtool_dict:
      [supported_ports]:             [ TP ]
      [supported_link_modes]:
        [supported_link_modes][0]:   10baseT/Half 10baseT/Full
        [supported_link_modes][1]:   100baseT/Half 100baseT/Full
        [supported_link_modes][2]:   1000baseT/Half 1000baseT/Full
      [supported_pause_frame_use]:   No
      [supports_auto-negotiation]:   Yes
      [supported_fec_modes]:         Not reported
      [advertised_link_modes]:
        [advertised_link_modes][0]:  10baseT/Half 10baseT/Full
        [advertised_link_modes][1]:  100baseT/Half 100baseT/Full
        [advertised_link_modes][2]:  1000baseT/Half 1000baseT/Full
      [advertised_pause_frame_use]:  Symmetric
      [advertised_auto-negotiation]: Yes
      [advertised_fec_modes]:        Not reported
      [speed]:                       Unknown!
      [duplex]:                      Unknown! (255)
      [port]:                        Twisted Pair
      [phyad]:                       1
      [transceiver]:                 internal
      [auto-negotiation]:            on
      [mdi-x]:                       Unknown
      [supports_wake-on]:            g
      [wake-on]:                     g
      [current_message_level]:       0x000000ff (255)
      [drv_probe_link_timer_ifdown_ifup_rx_err_tx_err]:<blank>
      [link_detected]:               no
    """

    # Using sed and tail to massage the data a bit before running
    # key_value_outbuf_to_dict.
    cmd_buf = (
        "ethtool "
        + interface_name
        + " | sed -re 's/(.* link modes:)(.*)/\\1\\n\\2/g' | tail -n +2"
    )
    stdout, stderr, rc = bsu.os_execute_command(cmd_buf)
    result = vf.key_value_outbuf_to_dict(stdout, process_indent=1, strip=" \t")

    return result


def to_json_ordered(json_str):
    r"""
    Parse the JSON string data and return an ordered JSON dictionary object.

    Description of argument(s):
    json_str                        The string containing the JSON data.
    """

    try:
        return json.loads(json_str, object_pairs_hook=DotDict)
    except TypeError:
        return json.loads(json_str.decode("utf-8"), object_pairs_hook=DotDict)


def get_bmc_release_info():
    r"""
    Get release info from the BMC and return as a dictionary.

    Example:

    ${release_info}=  Get BMC Release Info
    Rprint Vars  release_info

    Output:

    release_info:
      [id]:                           openbmc-phosphor
      [name]:                         Phosphor OpenBMC (Phosphor OpenBMC Project Reference...
      [version]:                      2.8.0-dev
      [version_id]:                   2.8.0-dev-1083-g8954c3505
      [pretty_name]:                  Phosphor OpenBMC (Phosphor OpenBMC Project Reference...
      [build_id]:                     2.8.0-dev
      [openbmc_target_machine]:       witherspoon
    """

    out_buf, stderr, rc = bsu.bmc_execute_command("cat /etc/os-release")
    return vf.key_value_outbuf_to_dict(out_buf, delim="=", strip='"')


def get_os_release_info():
    r"""
    Get release info from the OS and return as a dictionary.

    Example:

    ${release_info}=  Get OS Release Info
    Rprint Vars  release_info

    Output:
    release_info:
      [name]:                                         Red Hat Enterprise Linux Server
      [version]:                                      7.6 (Maipo)
      [id]:                                           rhel
      [id_like]:                                      fedora
      [variant]:                                      Server
      [variant_id]:                                   server
      [version_id]:                                   7.6
      [pretty_name]:                                  Red Hat Enterprise Linux Server 7.6 (Maipo)
      [ansi_color]:                                   0;31
      [cpe_name]:                                     cpe:/o:redhat:enterprise_linux:7.6:GA:server
      [home_url]:                                     https://www.redhat.com/
      [bug_report_url]:                               https://bugzilla.redhat.com/
      [redhat_bugzilla_product]:                      Red Hat Enterprise Linux 7
      [redhat_bugzilla_product_version]:              7.6
      [redhat_support_product]:                       Red Hat Enterprise Linux
      [redhat_support_product_version]:               7.6
    """

    out_buf, stderr, rc = bsu.os_execute_command("cat /etc/os-release")
    return vf.key_value_outbuf_to_dict(out_buf, delim="=", strip='"')


def pdbg(option_string, **bsu_options):
    r"""
    Run pdbg on the BMC with the caller's option string and return the output.

    Description of argument(s):
    option_string    A string of options which are to be processed by the pdbg command.
    bsu_options      Options to be passed directly to bmc_execute_command.  See its prolog for
                     details.
    """

    # Default print_out to 1.
    if "print_out" not in bsu_options:
        bsu_options["print_out"] = 1

    stdout, stderr, rc = bsu.bmc_execute_command(
        "pdbg " + option_string, **bsu_options
    )
    return stdout


def ecmd(option_string, **bsu_options):
    r"""
    Run ecmd command on the BMC with the caller's option string and return the output.

    Description of argument(s):
    option_string    A string of options which are to be executed on BMC.
                     (e.g. getscom pu 20010a40 -all,
                     putscom pu 20010a40 4000000000000000 -p0).
    bsu_options      Options to be passed directly to bmc_execute_command.  See its prolog for
                     details.
    """

    # Default print_out to 1.
    if "print_out" not in bsu_options:
        bsu_options["print_out"] = 1

    stdout, stderr, rc = bsu.bmc_execute_command(option_string, **bsu_options)
    return stdout


def split_string_with_index(stri, n):
    r"""
    To split every n characters and forms an element for every nth index

    Example : Given ${stri} = "abcdef", then the function call,
    ${data}=  Split List With Index  ${stri}  2
    then, result will be data = ['ab', 'cd', 'ef']
    """

    n = int(n)
    data = [stri[index : index + n] for index in range(0, len(stri), n)]
    return data


def remove_whitespace(instring):
    r"""
    Removes the white spaces around the string

    Example: instring = "  xxx  ", then returns instring = "xxx"
    """

    return instring.strip()


def zfill_data(data, num):
    r"""
    zfill() method adds zeros (0) at the beginning of the string, until it
    reaches the specified length.

    Usage : ${anystr}=  Zfill Data  ${data}  num

    Example : Binary of one Byte has 8 bits - xxxx xxxx

    Consider ${binary} has only 3 bits after converting from Hexadecimal/decimal to Binary
    Say ${binary} = 110 then,
    ${binary}=  Zfill Data  ${binary}  8
    Now ${binary} will be 0000 0110
    """

    return data.zfill(int(num))


def get_subsequent_value_from_list(list, value):
    r"""
    returns first index of the element occurrence.
    """

    index = [list.index(i) for i in list if value in i]
    return index


def return_decoded_string(input):
    r"""
    returns decoded string of encoded byte.
    """

    encoded_string = input.encode("ascii", "ignore")
    decoded_string = encoded_string.decode()
    return decoded_string


def remove_unicode_from_uri(uri):
    r"""
    returns dbus uri without unicode in prefix
    """

    return re.sub("`-|\\|-", "", uri)


def get_bmc_major_minor_version(version):
    r"""
    returns major version and minor version
    from cat /etc/os-release command.
    For example,
    xyz23.01 --> [23, 01]
    xyz.0-112 --> [0, 112]
    ZERzzYY-23.04-1-xx3 --> [23, 04, 1, 3]
    """

    return re.findall(r"\d+", re.sub("[A-Z]|[a-z]", "", version))


def convert_name_into_bytes_with_prefix(name):
    r"""
    Convert name into bytes with prefix 0x
    """

    bytes_list = []

    for letter in name:
        bytes_list.append(hex(ord(letter)))

    return bytes_list


def convert_name_into_bytes_without_prefix(name):
    r"""
    Convert name into bytes
    """

    tmp_lst = []

    for letter in name:
        value = convert_to_hex_value_without_prefix(letter)
        tmp_lst.append(value)

    return tmp_lst


def convert_to_hex_value_without_prefix(letter):
    r"""
    Convert into hex
    """

    value = hex(ord(letter))
    if value[:2] == "0x":
        value = value[2:]

    return value


def convert_prefix_hex_list_to_non_prefix_hex_list(list):
    r"""
    Convert into list of hex with prefix to list of hex without prefix.
    """

    tmp_list = []

    for value in list:
        if value[:2] == "0x":
            tmp_list.append(value[2:])

    return tmp_list


def convert_list_to_string(list):
    r"""
    returns list to string.
    """

    sensor_name = ""
    for character in list:
        sensor_name += character

    return sensor_name


def get_string_index(input, value):
    r"""
    returns index from the string.
    """

    return input.find(value)
