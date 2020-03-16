#!/usr/bin/env python

import os
import re
import json
from data import variables
from collections import OrderedDict

bmc_rec_pattern = '^=(.*)\n(.*)\n(.*)\n(.*)\n(.*)'
bmc_prop_pattern = [r"\w+", r"\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}", '443']
bmc_rec_prop = ['hostname', 'address', 'port', 'txt']


class Exception(Exception):
    def __init__(self, exc_value):
        self.exc_value = exc_value

    def __str__(self):
        return repr(self.exc_value)


def validate_bmc_properties(bmc_prop_pattern, bmc_prop, bmc_value,
                            bmc_rec_valid):
    r"""
    This function is to check pattern match in bmc properties.

    Description of arguments:
    bmc_prop_pattern       Regex pattern.
    bmc_prop               BMC property (e.g. hostname, address, port).
    bmc_value              BMC property value.
    bmc_rec_valid          Contain BMC properties record.
    """

    try:
        status = \
            [lambda bmc_prop: re.search(bmc_prop_pattern, bmc_prob),
                bmc_value]
        if None in status:
            bmc_rec_valid[bmc_prop] = None
    except Exception as exc_obj:
        return exc_obj
    finally:
        return bmc_rec_valid


def bmc_record_validation(bmc_rec_valid):
    r"""
    Parse the BMC records to validate the data is valid.

    Description of arguments:
    bmc_rec_valid          Contain BMC properties record.
    """

    try:
        for bmc_prop_key, bmc_pattern_val in \
                zip(bmc_rec_prop, bmc_prop_pattern):
            bmc_prop_value = bmc_rec_valid.get(bmc_prop_key, False)
            if bmc_rec_valid[bmc_prop_key] is not False:
                valid_status = validate_bmc_properties(bmc_pattern_val,
                                                       bmc_prop_key,
                                                       bmc_prop_value,
                                                       bmc_rec_valid)
                if None not in bmc_rec_valid.values():
                    return bmc_rec_valid
                else:
                    return None
    except Exception as exc_obj:
        return exc_obj


def bmc_inventory(service_type, bmc_inv_record):
    r"""
    Parse single record of BMC inventory and pack to dictionary form.

    Description of arguments:
    service_type       Service type (e.g. _obmc_rest._tcp, _obmc_redfish._tcp).
    bmc_inv_record     Individual BMC inventory record.

    This function will return this variable i.e.
    bmc_inv in dictionary form as mention below.

    Below are the discovered BMC detail.

    [service]:          _obmc_XXXX._tcp
    [hostname]:         System Name
    [address]:          XXX.XXX.XXX.XXX
    [port]:             XXX
    [txt]:
    """

    try:
        exc_obj = None
        bmc_inv = OrderedDict()
        service_count = 0
        for line in bmc_inv_record.split('\n'):
            if line == "":
                pass
            elif service_type in line:
                bmc_inv['service'] = service_type
                service_count += 1
            elif not line.startswith('=') and service_count == 1:
                bmc_inv[line.split('=')[0].strip()] = \
                    str(line.split('=')[-1].strip())[1:-1]
    except Exception as exc_obj:
        return exc_obj
    finally:
        valid_status = bmc_record_validation(bmc_inv)
        if valid_status is None:
            return None, exc_obj
        else:
            return valid_status, exc_obj


def get_bmc_records(service_type, bmc_records):
    r"""
    Parse the string to filter BMC discovery.

    Description of arguments:
    service_type     Service type (e.g. RESTService, RedfishService).
    bmc_records      Contains the lis of discoverd BMC records.

    This function will return this variable i.e.
    bmc_inv_list in dictionary form as mention below.

    Below are the list of discovered BMC details.
    [1]:
        [service]:          _obmc_XXXX._tcp
        [hostname]:         System Name
        [address]:          XXX.XXX.XXX.XXX
        [port]:             XXX
        [txt]:
    [2]:
        [service]:          _obmc_XXXX._tcp
        [hostname]:         System Name
        [address]:          XXX.XXX.XXX.XXX
        [port]:             XXX
        [txt]:
    """

    try:
        count = 0
        exe_obj = None
        bmc_inv_list = OrderedDict()
        for match in re.finditer(bmc_rec_pattern, bmc_records,
                                 re.MULTILINE):
            bmc_record, exc_msg = \
                bmc_inventory(service_type, match.group())
            if bmc_record is not None and exc_msg is None:
                count += 1
                bmc_inv_list[count] = bmc_record
    except Exception as exe_obj:
        return exe_obj
    finally:
        if len(bmc_inv_list) == 0:
            '', exe_obj
        else:
            return bmc_inv_list, exe_obj
