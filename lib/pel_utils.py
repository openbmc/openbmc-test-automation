#!/usr/bin/env python3

r"""
PEL functions.
"""

import func_args as fa
import bmc_ssh_utils as bsu
import json
import pel_variables


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
        except ValueError:
            return {}
    return out_buf


def fetch_all_pel_ids_for_src(src_id, severity):
    r"""
    Fetch all PEL IDs for the input SRC ID based on the severity type
    in the list format.

    Description of arguments:
    src_id      SRC ID (e.g. BC20E504).
    severity    PEL severity (e.g. "Predictive Error"
                                   "Recovered Error").
    """

    try:
        src_pel_ids = []
        pel_data = peltool(" -l")
        pel_id_list = pel_data.keys()
        for pel_id in pel_id_list:
            # Check if required SRC ID with severity is present
            if ((pel_data[pel_id]["SRC"] == src_id) and (pel_data[pel_id]["Sev"] == severity)):
                src_pel_ids.append(pel_id)

        if not src_pel_ids:
            raise peltool_exception(src_id + " with severity " +
                                    severity + " not present")
    except Exception as e:
        raise peltool_exception("Failed to fetch PEL ID for required SRC : " + str(e))
    return src_pel_ids


def verify_src_signature_and_threshold(pel_id, attn_type, signature_desc,
                                       threshold_limit):
    r"""
    Verifies SRC details for the given PEL ID based on the required
    attention type, signature description, threshold limits.

    Description of arguments:
    pel_id          PEL ID for the required SRC details to verify.
    attn_type       Attention type (e.g. RE, CS, UNIT_CS).
    signature_desc  Signature description of the error inject.
    threshold_limit Threshold limit (e.g. 1, 5, 32).
    """

    try:
        pel_cmd = " -i " + pel_id
        src_data = peltool(pel_cmd)
        src_dict = src_data["Primary SRC"]["SRC Details"]
        usr_data = src_data["User Data 1"]

        # Example for signature in recoverable error
        #
        # "SRC Details": {
        # "Attention Type": "RECOVERABLE",
        # "Node": 0,
        # "Target Type": "TYPE_OMIC",
        # "Target Instance": 0,
        # "Signature": "MC_OMI_DL_FIR[1]: OMI-DL0 UE on data flit"
        # }
        if (attn_type == "RE"):
            if (src_dict["Attention Type"] != "RECOVERABLE"):
                raise peltool_exception("Required Attention type " + attn_type + " not found")

        # Example for signature in system checkstop error
        #
        # "SRC Details": {
        # "Primary Attention": "system checkstop",
        # "Signature Description": {
        #    "Chip Desc": "node 0 proc 0 (P10 2.0)",
        #    "Signature": "EQ_L2_FIR(0)[7] L2 directory read UE",
        #    "Attn Type": "checkstop"
        # }

        elif (attn_type == "CS"):
            if (src_dict["Primary Attention"] != "system checkstop"):
                raise peltool_exception("Required Attention type " + attn_type + " not found")

        elif (attn_type == "UNIT_CS"):
            if (src_dict["Attention Type"] != "UNIT_CS"):
                raise peltool_exception("Required Attention type " + attn_type + " not found")
        else:
            raise peltool_exception("Required Attention type " + attn_type + " not found")

        if signature_desc not in src_dict["Signature"]:
            raise peltool_exception("Required Signature " + signature_desc + " not found")

        if (int(threshold_limit) != usr_data["Error Count"]):
            raise peltool_exception("Required Threshold limit " +
                                    threshold_limit + " not found")

    except Exception as e:
        raise peltool_exception("Failed to verify SRC details : " + str(e))
    return True


def fetch_all_src():
    r"""
    Fetch all SRC IDs from peltool in the list format.
    """
    try:
        src_id = []
        pel_data = peltool(" -l")
        if pel_data:
            pel_id_list = pel_data.keys()
            for pel_id in pel_id_list:
                src_id.append(pel_data[pel_id]["SRC"])
        else:
            raise peltool_exception("No PEL entry found ..")
    except Exception as e:
        raise peltool_exception("Failed to fetch all SRCs : " + str(e))
    return src_id
