#!/usr/bin/env python

import json
import os
from collections import OrderedDict
import re

# The code base directory will be one level up
# from the directory containing this module.
code_base_dir_path = os.path.dirname(os.path.dirname(__file__)) + os.sep

json_directory = 'data'
json_file_name = 'BMC_publish_service.json'
bmc_rec_pattern = '^=(.*)\n(.*)\n(.*)\n(.*)\n(.*)'
bmc_prop_pattern = ['\w+', '\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}', '443']
bmc_rec_prop = ['hostname', 'address', 'port', 'txt']


def validate_bmc_properties(bmc_prop_pattern, bmc_prop, bmc_value, bmc_rec_valid):
    r"""
    This function is to check pattern match in bmc properties.

    Description of arguments:
    bmc_prop_pattern       Regex pattern.
    bmc_prop               BMC property (e.g. hostname, address, port).
    bmc_value              BMC property value.
    bmc_rec_valid          Contain BMC properties record.
    """

    try:
        exc_obj = None
        status = \
            [lambda bmc_prop: re.search(bmc_prop_pattern, bmc_prob),
                bmc_prop_value[bmc_prop]]
        if None in status:
            bmc_rec_valid[bmc_prop] = None
    except Exception as exc_obj:
        return exc_obj


def bmc_record_validation(bmc_rec_valid):
    r"""
    Parse the BMC records to validate the data is valid.

    Description of arguments:
    bmc_rec_valid          Contain BMC properties record.
    """

    try:
        exc_obj = None
        for bmc_prop_key, bmc_pattern_val in zip(bmc_rec_prop, bmc_prop_pattern):
            bmc_prop_value = bmc_rec_valid.get(bmc_prop_key, False)
            if bmc_rec_valid[bmc_prop_key] is not False:
                valid_status = validate_bmc_properties(bmc_rec_prop,
                                                       bmc_prop_key,
                                                       bmc_prop_value,
                                                       bmc_rec_valid)
                if None not in bmc_rec_valid:
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
    [hostname]:         [System Name]
    [address]:          [XXX.XXX.XXX.XXX]
    [port]:             [XXX]
    [txt]:              []
    """

    try:
        bmc_inv = OrderedDict()
        exc_obj = None
        service_count = 0
        for line in bmc_inv_record.splitlines():
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
        if valid_status is not None:
            return bmc_inv, exc_obj
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
        [service]:          _obmc_redfish._tcp
        [hostname]:         [System Name]
        [address]:          [XXX.XXX.XXX.XXX]
        [port]:             [XXX]
        [txt]:              []
    [2]:
        [service]:          _obmc_redfish._tcp
        [hostname]:         [System Name]
        [address]:          [XXX.XXX.XXX.XXX]
        [port]:             [XXX]
        [txt]:              []
    """

    try:
        count = 0
        bmc_inv_list = OrderedDict()
        exc_obj = None
        file_path = \
            os.path.join(code_base_dir_path, json_directory, json_file_name)

        if os.path.exists(file_path):
            with open(file_path, 'r') as file_obj:
                json_data = json.load(file_obj)

            service_type = json_data[service_type].split(' ')[-1].strip()
            for match in re.finditer(bmc_rec_pattern, bmc_records, re.MULTILINE):
                bmc_record, exc_msg = \
                    bmc_inventory(service_type, match.group())
                # Here BMC record should have 5 element So, it gets added to BMC record list.
                if bmc_record is not None and exc_msg is None:
                    count += 1
                    bmc_inv_list[count] = bmc_record
        else:
            exc_obj = "Json file not found: " + file_path
    except Exception as exc_obj:
        return exc_obj
    finally:
        return bmc_inv_list, exc_obj
