#!/usr/bin/env python3

r"""
PEL functions.
"""

import json
import os
import sys
from datetime import datetime

import bmc_ssh_utils as bsu
import func_args as fa

base_path = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.append(base_path + "/data/")

import pel_variables  # NOQA


class PeltoolException(Exception):
    r"""
    Base class for peltool related exceptions.
    """

    def __init__(self, message):
        self.message = message
        super().__init__(self.message)


def peltool(
    option_string, peltool_extension=None, parse_json=True, **bsu_options
):
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
    option_string                   A string of options which are to be
                                    processed by the peltool command.
    peltool_extension               Provide peltool extension format.
                                    Default: None.
    parse_json                      Indicates that the raw JSON data should
                                    parsed into a list of dictionaries.
    bsu_options                     Options to be passed directly to
                                    bmc_execute_command. See its prolog for
                                    details.
    """

    bsu_options = fa.args_to_objects(bsu_options)
    peltool_cmd = "peltool"
    if peltool_extension:
        peltool_cmd = peltool_cmd + peltool_extension

    out_buf, _, _ = bsu.bmc_execute_command(
        peltool_cmd + " " + option_string, **bsu_options
    )
    if parse_json:
        try:
            return json.loads(out_buf)
        except ValueError as e:
            if type(out_buf) is str:
                return out_buf
            else:
                print(str(e))
                return {}
    return out_buf


def get_pel_data_from_bmc(
    include_hidden_pels=False, include_informational_pels=False
):
    r"""
    Returns PEL data from BMC else throws exception.

    Description of arguments:
    include_hidden_pels           True/False (default: False).
                                  Set True to get hidden PELs else False.
    include_informational_pels    True/False (default: False).
                                  Set True to get informational PELs else False.
    """
    try:
        pel_cmd = " -l"
        if include_hidden_pels:
            pel_cmd = pel_cmd + " -h"
        if include_informational_pels:
            pel_cmd = pel_cmd + " -f"
        pel_data = peltool(pel_cmd)
        if not pel_data:
            print("No PEL data present in BMC ...")
    except Exception as exception:
        raise PeltoolException(
            "Failed to get PEL data from BMC : " + str(exception)
        ) from exception
    return pel_data


def verify_no_pel_exists_on_bmc():
    r"""
    Verify that no PEL exists in BMC. Raise an exception if it does.
    """

    try:
        pel_data = get_pel_data_from_bmc()

        if len(pel_data) == 0:
            return True

        print("PEL data present. \n", pel_data)
        raise PeltoolException("PEL data present in BMC")
    except Exception as exception:
        raise PeltoolException(
            "Failed to get PEL data from BMC : " + str(exception)
        ) from exception


def compare_pel_and_redfish_event_log(pel_record, event_record):
    r"""
    Compare PEL log attributes like "SRC", "Created at" with Redfish
    event log attributes like "EventId", "Created".
    Return False if they do not match.

    Description of arguments:
    pel_record     PEL record.
    event_record   Redfish event which is equivalent of PEL record.
    """

    try:
        # Below is format of PEL record / event record and following
        # i.e. "SRC", "Created at" from
        # PEL record is compared with "EventId", "Created" from event record.

        # PEL Log attributes
        # SRC        : XXXXXXXX
        # Created at : 11/14/2022 12:38:04

        # Event log attributes
        # EventId : XXXXXXXX XXXXXXXX XXXXXXXXX XXXXXXXX XXXXXXXX XXXXXXXX

        # Created : 2022-11-14T12:38:04+00:00

        print(f"\nPEL records : {pel_record}")
        print(f"\nEvent records : {event_record}")

        pel_src = pel_record["pel_data"]["SRC"]
        pel_created_time = pel_record["pel_detail_data"]["Private Header"][
            "Created at"
        ]

        event_ids = (event_record["EventId"]).split(" ")

        event_time_format = (event_record["Created"]).split("T")
        event_date = (event_time_format[0]).split("-")
        event_date = datetime(
            int(event_date[0]), int(event_date[1]), int(event_date[2])
        )
        event_date = event_date.strftime("%m/%d/%Y")
        event_sub_time_format = (event_time_format[1]).split("+")
        event_date_time = event_date + " " + event_sub_time_format[0]

        event_created_time = event_date_time.replace("-", "/")

        print(f"\nPEL SRC : {pel_src} | PEL Created Time : {pel_created_time}")

        print(
            f"\nError event ID : {event_ids[0]} | Error Log Created Time "
            + ": {event_created_time}"
        )

        if pel_src == event_ids[0] and pel_created_time == event_created_time:
            print(
                "\nPEL SRC and created date time match with "
                "event ID, created time"
            )
        else:
            raise PeltoolException(
                "\nPEL SRC and created date time did not "
                "match with event ID, created time"
            )
    except Exception as exception:
        raise PeltoolException(
            "Exception occurred during PEL and Event log "
            "comparison for SRC or event ID and created "
            "time : " + str(exception)
        ) from exception


def fetch_all_pel_ids_for_src(src_id, severity, include_hidden_pels=False):
    r"""
    Fetch all PEL IDs for the input SRC ID based on the severity type
    in the list format.

    Description of arguments:
    src_id                SRC ID (e.g. BCXXYYYY).
    severity              PEL severity (e.g. "Predictive Error"
                                             "Recovered Error").
    include_hidden_pels   True/False (default: False).
                          Set True to get hidden PELs else False.
    """

    try:
        src_pel_ids = []
        pel_data = get_pel_data_from_bmc(include_hidden_pels)
        pel_id_list = pel_data.keys()
        for pel_id in pel_id_list:
            # Check if required SRC ID with severity is present
            if src_id in pel_data[pel_id]["SRC"]:
                if pel_data[pel_id]["Sev"] == severity:
                    src_pel_ids.append(pel_id)

        if not src_pel_ids:
            raise PeltoolException(
                src_id + " with severity " + severity + " not present"
            )
    except Exception as exception:
        raise PeltoolException(
            "Failed to fetch PEL ID for required SRC : " + str(exception)
        ) from exception
    return src_pel_ids


def fetch_all_src(include_hidden_pels=False):
    r"""
    Fetch all SRC IDs from peltool in the list format.

    include_hidden_pels       True/False (default: False).
                              Set True to get hidden PELs else False.
    """
    try:
        src_id = []
        pel_data = get_pel_data_from_bmc(include_hidden_pels)
        if pel_data:
            pel_id_list = pel_data.keys()
            for pel_id in pel_id_list:
                src_id.append(pel_data[pel_id]["SRC"])
        print("SRC IDs: " + str(src_id))
    except Exception as exception:
        raise PeltoolException(
            "Failed to fetch all SRCs : " + str(exception)
        ) from exception
    return src_id


def check_for_unexpected_src(
    unexpected_src_list=None, include_hidden_pels=False
):
    r"""
    From the given unexpected SRC list, check if any unexpected SRC created
    on the BMC. Returns 0 if no SRC found else throws exception.

    Description of arguments:
    unexpected_src_list       Give unexpected SRCs in the list format.
                              e.g.: ["BBXXYYYY", "AAXXYYYY"].

    include_hidden_pels       True/False (default: False).
                              Set True to get hidden PELs else False.
    """
    try:
        unexpected_src_count = 0
        if not unexpected_src_list:
            print("Unexpected SRC list is empty.")
        src_data = fetch_all_src(include_hidden_pels)
        for src in unexpected_src_list:
            if src in src_data:
                print("Found an unexpected SRC : " + src)
                unexpected_src_count = unexpected_src_count + 1
        if unexpected_src_count >= 1:
            raise PeltoolException("Unexpected SRC found.")

    except Exception as exception:
        raise PeltoolException(
            "Failed to verify unexpected SRC list : " + str(exception)
        ) from exception
    return unexpected_src_count


def filter_unexpected_srcs(expected_srcs=None):
    r"""
    Return list of SRCs found in BMC after filtering expected SRCs.
    If expected_srcs is None then all SRCs found in system are returned.

    Description of arguments:
    expected_srcs       List of expected SRCs. E.g. ["BBXXYYYY", "AAXXYYYY"].
    """

    srcs_found = fetch_all_src()
    if not expected_srcs:
        expected_srcs = []
    print(expected_srcs)
    return list(set(srcs_found) - set(expected_srcs))


def get_bmc_event_log_id_for_pel(pel_id):
    r"""
    Return BMC event log ID for the given PEL ID.

    Description of arguments:
    pel_id       PEL ID. E.g. 0x50000021.
    """

    pel_data = peltool("-i " + pel_id)
    print(pel_data)
    bmc_id_for_pel = pel_data["Private Header"]["BMC Event Log Id"]
    return bmc_id_for_pel


def get_latest_pels(number_of_pels=1):
    r"""
    Return latest PEL IDs.

    Description of arguments:
    number_of_pels       Number of PELS to be returned.
    """

    pel_data = peltool("-lr")
    pel_ids = list(pel_data.keys())
    return pel_ids[:number_of_pels]
