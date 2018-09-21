#!/usr/bin/env python

r"""
This module provides many valuable openbmctool.py functions such as
openbmctool_execute_command.
"""

import gen_print as gp
import gen_cmd as gc
import gen_valid as gv
import gen_misc as gm
import var_funcs as vf
from robot.libraries.BuiltIn import BuiltIn
import re


def openbmctool_execute_command(command_string,
                                *args,
                                **kwargs):
    r"""
    Run the command string as an argument to the openbmctool.py program and
    return the stdout and the return code.

    This function provides several benefits versus calling shell_cmd directly:
    - This function will obtain the global values for OPENBMC_HOST,
      OPENBMC_USERNAME, etc.
    - This function will compose the openbmctool.py command string which
      includes the caller's command_string.
    - The openbmctool.py produces additional text that clutters the output.
      This function will remove such text.  Example:
        Attempting login...
        <actual output>
        User root has been logged out

    NOTE: If you have pipe symbols in your command_string, they must be
    surrounded by a single space on each side (see example below).

    Example code:
    ${rc}  ${output}=  Openbmctool Execute Command  fru status | head -n 2

    Example output:
    #(CDT) 2018/09/19 15:16:58 - Issuing: set -o pipefail ; openbmctool.py -H hostname -U root -P ********
    ...  fru status | tail -n +1 | egrep -v 'Attempting login|User [^ ]+ hasbeen logged out' | head -n 2
    Component     | Is a FRU  | Present  | Functional  | Has Logs
    cpu0          | Yes       | Yes      | Yes         | No

    Description of arguments:
    command_string                  The command string to be passed to the
                                    openbmctool.py program.
    All remaining arguments are passed directly to shell_cmd.  See the
    shell_cmd prolog for details on allowable arguments.  The caller may code
    them directly as in this example:
    openbmctool_execute_command("my command", quiet=1, max_attempts=2).
    Python will do the work of putting these values into args/kwargs.
    """

    if not gv.valid_value(command_string):
        return "", "", 1

    # Get global BMC variable values.
    openbmc_host = BuiltIn().get_variable_value("${OPENBMC_HOST}", default="")
    openbmc_username = BuiltIn().get_variable_value("${OPENBMC_USERNAME}",
                                                    default="")
    openbmc_password = BuiltIn().get_variable_value("${OPENBMC_PASSWORD}",
                                                    default="")
    if not gv.valid_value(openbmc_host):
        return "", "", 1
    if not gv.valid_value(openbmc_username):
        return "", "", 1
    if not gv.valid_value(openbmc_password):
        return "", "", 1

    # Break the caller's command up into separate piped commands.  For
    # example, the user may have specified "fru status | head -n 2" which
    # would be broken into 2 list elements.
    pipeline = map(str.strip, re.split(r' \| ', str(command_string)))
    # The "tail" command below prevents a "egrep: write error: Broken pipe"
    # error if the user is piping the output to a sub-process.
    # Use "egrep -v" to get rid of editorial output from openbmctool.py.
    pipeline.insert(1, "tail -n +1 | egrep -v 'Attempting login|User [^ ]+ has"
                    " been logged out'")

    command_string = "set -o pipefail ; openbmctool.py -H " + openbmc_host\
        + " -U " + openbmc_username + " -P " + openbmc_password + " "\
        + " | ".join(pipeline)

    return gc.shell_cmd(command_string, *args, **kwargs)


def get_fru_status():
    r"""
    Get the fru status and return as a list of dictionaries.

    Example robot code:

    ${fru_status}=  Get Fru Status
    Rprint Vars  1  fru_status

    Example result (excerpt):

    fru_status:
      fru_status[0]:
        [component]:             cpu0
        [is_a]:                  Yes
        [fru]:                   Yes
        [present]:               Yes
        [functional]:            No
      fru_status[1]:
        [component]:             cpu0-core0
        [is_a]:                  No
        [fru]:                   Yes
        [present]:               Yes
        [functional]:            No
    ...
    """
    rc, output = openbmctool_execute_command("fru status", print_output=False,
                                             ignore_err=False)
    # Example value for output (partial):
    # Component     | Is a FRU  | Present  | Functional  | Has Logs
    # cpu0          | Yes       | Yes      | Yes         | No
    # cpu0-core0    | No        | Yes      | Yes         | No
    # ...

    # Replace spaces with underscores in field names (e.g. "Is a FRU" becomes
    # "Is_a_FRU").
    output = re.sub("([^ \\|])[ ]([^ ])", "\\1_\\2", output)
    output = re.sub("([^ \\|])[ ]([^ ])", "\\1_\\2", output)

    return vf.outbuf_to_report(output, field_delim="|")


def get_fru_print(parse_json=True):
    r"""
    Get the output of the fru print command and return it either as raw JSON
    data or as a list of dictionaries.

    Example robot code:

    ${fru_print}=  Get Fru Print  parse_json=${False}
    Log to Console  ${fru_print}

    Example result (excerpt):

    {
      "data": {
        "/xyz/openbmc_project/inventory/system": {
          "AssetTag": "",
          "BuildDate": "",
          "Cached": false,
          "FieldReplaceable": false,
          "Manufacturer": "",
          "Model": "8335-GTC",
          "PartNumber": "",
          "Present": true,
          "PrettyName": "",
          "SerialNumber": "13183FA"
        },
        "/xyz/openbmc_project/inventory/system/chassis": {
          "AirCooled": true,
          "WaterCooled": false
        },
    ...

    Example robot code:

    ${fru_print}=  Get Fru Print
    Rprint Vars  1  fru_print

    Example result (excerpt):

    fru_print:
      fru_print[0]:
        [data]:
          [/xyz/openbmc_project/inventory/system]:
            [AssetTag]:          <blank>
            [BuildDate]:         <blank>
            [Cached]:            False
            [FieldReplaceable]:  False
            [Manufacturer]:      <blank>
            [Model]:             8335-GTC
            [PartNumber]:        <blank>
            [Present]:           True
            [PrettyName]:        <blank>
            [SerialNumber]:      13183FA
          [/xyz/openbmc_project/inventory/system/chassis]:
            [AirCooled]:         True
            [WaterCooled]:       False
    ...

    Description of argument(s):
    parse_json                      Indicates that the raw JSON data should
                                    parsed into a list of dictionaries.
    """

    rc, output = openbmctool_execute_command("fru print", print_output=False,
                                             ignore_err=False)
    if parse_json:
        return gm.json_loads_multiple(output)
    else:
        return output


def get_fru_list(parse_json=True):
    r"""
    Get the output of the fru list command and return it either as raw JSON
    data or as a list of dictionaries.

    Example robot code:

    ${fru_list}=  Get Fru List  parse_json=${False}
    Log to Console  ${fru_list}

    Example result (excerpt):

    {
      "data": {
        "/xyz/openbmc_project/inventory/system": {
          "AssetTag": "",
          "BuildDate": "",
          "Cached": false,
          "FieldReplaceable": false,
          "Manufacturer": "",
          "Model": "8335-GTC",
          "PartNumber": "",
          "Present": true,
          "PrettyName": "",
          "SerialNumber": "13183FA"
        },
        "/xyz/openbmc_project/inventory/system/chassis": {
          "AirCooled": true,
          "WaterCooled": false
        },
    ...

    Example robot code:

    ${fru_list}=  Get Fru List
    Rprint Vars  1  fru_list

    Example result (excerpt):

    fru_list:
      fru_list[0]:
        [data]:
          [/xyz/openbmc_project/inventory/system]:
            [AssetTag]:          <blank>
            [BuildDate]:         <blank>
            [Cached]:            False
            [FieldReplaceable]:  False
            [Manufacturer]:      <blank>
            [Model]:             8335-GTC
            [PartNumber]:        <blank>
            [Present]:           True
            [PrettyName]:        <blank>
            [SerialNumber]:      13183FA
          [/xyz/openbmc_project/inventory/system/chassis]:
            [AirCooled]:         True
            [WaterCooled]:       False
    ...

    Description of argument(s):
    parse_json                      Indicates that the raw JSON data should
                                    parsed into a list of dictionaries.
    """

    rc, output = openbmctool_execute_command("fru list", print_output=False,
                                             ignore_err=False)
    if parse_json:
        return gm.json_loads_multiple(output)
    else:
        return output


def get_sensors_print():

    r"""
    Get the output of the sensors print command and return as a list of
    dictionaries.

    Example robot code:

    ${sensors_print}=  Get Sensors Print
    Rprint Vars  1  sensors_print

    Example result (excerpt):

    sensors_print:
      sensors_print[0]:
        [sensor]:                OCC0
        [type]:                  Discrete
        [units]:                 N/A
        [value]:                 Active
        [target]:                Active
      sensors_print[1]:
        [sensor]:                OCC1
        [type]:                  Discrete
        [units]:                 N/A
        [value]:                 Active
        [target]:                Active
    ...
    """
    rc, output = openbmctool_execute_command("sensors print",
                                             print_output=False,
                                             ignore_err=False)
    # Example value for output (partial):
    # sensor                 | type         | units     | value    | target
    # OCC0                   | Discrete     | N/A       | Active   | Active
    # OCC1                   | Discrete     | N/A       | Active   | Active

    return vf.outbuf_to_report(output, field_delim="|")


def get_sensors_list():

    r"""
    Get the output of the sensors list command and return as a list of
    dictionaries.

    Example robot code:

    ${sensors_list}=  Get Sensors List
    Rprint Vars  1  sensors_list

    Example result (excerpt):

    sensors_list:
      sensors_list[0]:
        [sensor]:                OCC0
        [type]:                  Discrete
        [units]:                 N/A
        [value]:                 Active
        [target]:                Active
      sensors_list[1]:
        [sensor]:                OCC1
        [type]:                  Discrete
        [units]:                 N/A
        [value]:                 Active
        [target]:                Active
    ...
    """
    rc, output = openbmctool_execute_command("sensors list",
                                             print_output=False,
                                             ignore_err=False)
    # Example value for output (partial):
    # sensor                 | type         | units     | value    | target
    # OCC0                   | Discrete     | N/A       | Active   | Active
    # OCC1                   | Discrete     | N/A       | Active   | Active

    return vf.outbuf_to_report(output, field_delim="|")


def get_openbmctool_version():
    r"""
    Get the openbmctool.py version and return it.

    Example robot code:
    ${openbmctool_version}=  Get Openbmctool Version
    Rprint Vars  openbmctool_version

    Example result (excerpt):
    openbmctool_version:         1.06
    """
    rc, output = openbmctool_execute_command("-V | cut -f 2 -d ' '",
                                             print_output=False,
                                             ignore_err=False)
    return output
