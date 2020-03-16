#!/usr/bin/env python

import json
import os
from collections import OrderedDict
import re

# The code base directory will be one level up
# from the directory containing this module.
code_base_dir_path = os.path.dirname(os.path.dirname(__file__)) + os.sep

json_directory = "data"
json_file_name = "BMC_publish_service.json"
pattern = "^=(.*)\n(.*)\n(.*)\n(.*)\n(.*)"


def bmc_inventory(service_type, bmc_inv_record):
    r"""
    Parse single record of BMC inventory and pack to dictionary form.

    Description of arguments:
    service_type       Service type (e.g. _obmc_rest._tcp, _obmc_redfish._tcp).
    bmc_inv_record     Individual BMC inventory record.
    """

    try:
        bmc_inv = OrderedDict()
        exc_obj = None
        service_count = 0
        for index, line in enumerate(bmc_inv_record.splitlines()):
            if line == "":
                pass
            elif service_type in line:
                bmc_inv['service'] = service_type
                service_count += 1
            elif not line.startswith('=') and service_count == 1:
                bmc_inv[line.split('=')[0].strip()] = \
                    line.split('=')[-1].strip()
    except Exception as exc_obj:
        return exc_obj
    finally:
        return bmc_inv, exc_obj


def get_bmc_records(service_type, bmc_records):
    r"""
    Parse the string to filter BMC discovery.

    Description of arguments:
    service_type     Service type (e.g. RESTService, RedfishService).
    bmc_records      Contains the lis of discoverd BMC records.
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
            for match in re.finditer(pattern, bmc_records, re.MULTILINE):
                bmc_record, exc_msg = \
                    bmc_inventory(service_type, match.group())
                if len(bmc_record) == 5 and exc_msg is None:
                    count += 1
                    bmc_inv_list[count] = bmc_record
        else:
            exc_obj = "Json file not found: " + file_path
    except Exception as exc_obj:
        return exc_obj
    finally:
        return bmc_inv_list, exc_obj
