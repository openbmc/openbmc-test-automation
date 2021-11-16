#!/usr/bin/env python3

r"""
PEL functions.
"""

import func_args as fa
import bmc_ssh_utils as bsu
import json


class peltool_exception(Exception):
    r"""
    Base class for peltool related exceptions.
    """
    def __init__(self, message):
        self.message = message
        super().__init__(self.message)

def peltool(option_string, parse_json=True, **bsu_options):
    r"""
    Run peltool on the BMC with the caller's option string and return the result.

    Example:

    ${pel_results}=  Peltool  -l
    Rprint Vars  pel_results

    pel_results:
      [0x50000031]:
        [CompID]:                       0x1000
        [PLID]:                         0x50000031
        [Subsystem]:                    BMC Firmware
        [Message]:                      An application had an internal failure
        [SRC]:                          BD8D1002
        [Commit Time]:                  02/25/2020  04:51:31
        [Sev]:                          Unrecoverable Error
        [CreatorID]:                    BMC

    Description of argument(s):
    option_string                   A string of options which are to be processed by the peltool command.
    parse_json                      Indicates that the raw JSON data should parsed into a list of
                                    dictionaries.
    bsu_options                     Options to be passed directly to bmc_execute_command. See its prolog for
                                    details.
    """

    bsu_options = fa.args_to_objects(bsu_options)
    out_buf, stderr, rc = bsu.bmc_execute_command('peltool ' + option_string, **bsu_options)
    if parse_json:
        try:
            return json.loads(out_buf)
        except json.JSONDecodeError:
            return {}
    return out_buf


def fetch_pelId_For_SRC(src_id):
    r"""
    Fetch PEL ID for the input SRC ID

    Description of arguments:
    src_id  SRC ID (e.g. BC20E504)
    """

    src_pel_id = []
    try:
        pel_data = peltool(" -l")
        pel_id_list = pel_data.keys()
        for i in pel_id_list:
            if pel_data[i]["SRC"] == src_id:
                src_pel_id.append(i)
    except Exception as e:
        raise peltool_exception("Failed to fetch PEL ID for required SRC : " + str(e))
    return src_pel_id


def verify_SRC_details(pel_id, attn_type, target_type, signature_desc,
                       threshold_limit):
    r"""
    Verify SRC details for the given PEL ID based on the required
    target type, attention type, signature description, threshold limit.

    Description of arguments:
    pel_id          PEL ID for the required SRC details to verify
    target_type     Target type (e.g. TYPE_OMIC)
    attn_type       Attention type (e.g. RECCOVERABLE)
    signature_desc  Signature description of the error inject
    threshold_limit Threshold limit (e.g. 1, 5, 32)
    """

    try:
        pel_cmd = " -i " + pel_id
        src_data = peltool(pel_cmd)
        src_dict = src_data["Primary SRC"]["SRC Details"]
        usr_data = src_data["User Data 4"]
        if (src_dict["Attention Type"] != attn_type):
            raise peltool_exception("Required Attention type " + attn_type + " not found")
        if target_type not in src_dict["Target Type"]:
            raise peltool_exception("Required Target type " + target_type + " not found")
        if signature_desc not in src_dict["Signature"]:
            raise peltool_exception("Required Signature " + signature_desc + " not found")

        if (int(threshold_limit) != usr_data["Error Threshold"]):
            raise peltool_exception("Required Threshold limit " + threshold_limit + " not found")

    except Exception as e:
        raise peltool_exception("Failed to verify SRC details : " + str(e))

    return True


def fetch_All_SRC():
    r"""
    Fetch all list of SRC IDs from peltool
    """

    src_id = []
    try:
        pel_data = peltool(" -l")
        pel_id_list = pel_data.keys()
        for i in pel_id_list:
            src_id.append(pel_data[i]["SRC"])
    except Exception as e:
        raise peltool_exception("Failed to fetch all SRCs : " + str(e))
    return src_id
