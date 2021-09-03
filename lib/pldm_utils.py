#!/usr/bin/env python3

r"""
PLDM functions.
"""

import re
import var_funcs as vf
import func_args as fa
import bmc_ssh_utils as bsu
import json
import random
import string
from robot.api import logger


def pldmtool(option_string, **bsu_options):

    r"""
    Run pldmtool on the BMC with the caller's option string and return the result.

    Example:

    ${pldm_results}=  Pldmtool  base GetPLDMTypes
    Rprint Vars  pldm_results

    pldm_results:
      pldmtool base GetPLDMVersion -t 0
      {
          "Response": "1.0.0"
      }

    Description of argument(s):
    option_string                   A string of options which are to be processed by the pldmtool command.
    parse_results                   Parse the pldmtool results and return a dictionary rather than the raw
                                    pldmtool output.
    bsu_options                     Options to be passed directly to bmc_execute_command.  See its prolog for
                                    details.
    """

    # This allows callers to specify arguments in python style (e.g. print_out=1 vs. print_out=${1}).
    bsu_options = fa.args_to_objects(bsu_options)

    stdout, stderr, rc = bsu.bmc_execute_command('pldmtool ' + option_string, **bsu_options)
    if stderr:
        return stderr
    try:
        return json.loads(stdout)
    except ValueError:
        return stdout


def GetBIOSEnumAttributeOptionalValues(attr_val_table_data):

    """
    From pldmtool GetBIOSTable of type AttributeValueTable get the dict of
    attribute handle and its optional values for BIOS Enumeration type.

    Description of argument(s):
    attr_val_table_data     pldmtool output from GetBIOSTable table type AttributeValueTable
                            e.g.
                            [{
                                  "AttributeHandle": 20,
                                  "AttributeNameHandle": "23(pvm-pcie-error-inject)",
                                  "AttributeType": "BIOSEnumeration",
                                  "NumberOfPossibleValues": 2,
                                  "PossibleValueStringHandle[0]": "3(Disabled)",
                                  "PossibleValueStringHandle[1]": "4(Enabled)",
                                  "NumberOfDefaultValues": 1,
                                  "DefaultValueStringHandleIndex[0]": 1,
                                  "StringHandle": "4(Enabled)"
                             }]
    @return                  Dictionary of BIOS attribute and its value.
                             e.g. {'pvm_pcie_error_inject': ['Disabled', 'Enabled']}
    """

    attr_val_data_dict = {}
    for item in attr_val_table_data:
        for attr in item:
            if (attr == "NumberOfPossibleValues"):
                value_list = []
                for i in range(0, int(item[attr])):
                    attr_values = item["PossibleValueStringHandle[" + str(i) + "]"]
                    value = re.search(r'\((.*?)\)', attr_values).group(1)
                    if value:
                        # Example:
                        # value = '"Power Off"'
                        if ' ' in value:
                            value = '"' + value + '"'
                        value_list.append(value)
                    else:
                        value_list.append('')

                attr_handle = re.findall(r'\(.*?\)', item["AttributeNameHandle"])
                attr_val_data_dict[attr_handle[0][1:-1]] = value_list
    return attr_val_data_dict


def GetBIOSStrAndIntAttributeHandles(attr_type, attr_val_table_data):

    """
    From pldmtool GetBIOSTable of type AttributeValueTable get the dict of
    attribute handle and its values based on the attribute type.

    Description of argument(s):
    attr_type               "BIOSInteger" or "BIOSString".
    attr_val_table_data     pldmtool output from GetBIOSTable table type AttributeValueTable.

    @return                 Dict of BIOS attribute and its value based on attribute type.

    """
    attr_val_int_dict = {}
    attr_val_str_dict = {}
    for item in attr_val_table_data:
        value_dict = {}
        attr_handle = re.findall(r'\(.*?\)', item["AttributeNameHandle"])
        # Example:
        # {'vmi_if0_ipv4_prefix_length': {'UpperBound': 32, 'LowerBound': 0}
        if (item["AttributeType"] == "BIOSInteger"):
            value_dict["LowerBound"] = item["LowerBound"]
            value_dict["UpperBound"] = item["UpperBound"]
            attr_val_int_dict[attr_handle[0][1:-1]] = value_dict
        # Example:
        # {'vmi_if1_ipv4_ipaddr': {'MaximumStringLength': 15, 'MinimumStringLength': 7}}
        elif (item["AttributeType"] == "BIOSString"):
            value_dict["MinimumStringLength"] = item["MinimumStringLength"]
            value_dict["MaximumStringLength"] = item["MaximumStringLength"]
            attr_val_str_dict[attr_handle[0][1:-1]] = value_dict

    if (attr_type == "BIOSInteger"):
        return attr_val_int_dict
    elif (attr_type == "BIOSString"):
        return attr_val_str_dict


def GetRandomBIOSIntAndStrValues(attr_name, count):

    """
    Get random integer or string values for BIOS attribute values based on the count.

    Description of argument(s):
    attr_name               Attribute name of BIOS attribute type Integer or string.
    count                   Max length for BIOS attribute type Integer or string.

    @return                 Random attribute value based on BIOS attribute type Integer
                            or string.

    """
    attr_random_value = ''

    # Example
    # 12.13.14.15
    if 'gateway' in attr_name:
        attr_random_value = ".".join(map(str, (random.randint(0, 255) for _ in range(4))))
    # Example
    # 11.11.11.11
    elif 'ipaddr' in attr_name:
        attr_random_value = ".".join(map(str, (random.randint(0, 255) for _ in range(4))))
    # Example
    # E5YWEDWJJ
    elif 'name' in attr_name:
        data = string.ascii_uppercase + string.digits
        attr_random_value = ''.join(random.choice(data) for _ in range(int(count)))

    elif 'mfg_flags' in attr_name:
        data = string.ascii_uppercase + string.digits
        attr_random_value = ''.join(random.choice(data) for _ in range(int(count)))

    elif 'hb_lid_ids' in attr_name:
        attr_random_value = str(random.randint(0, int(count)))

    else:
        attr_random_value = random.randint(0, int(count))
    return attr_random_value


def GetBIOSAttrOriginalValues(attr_val_table_data):

    """
    From pldmtool GetBIOSTable of type AttributeValueTable get the dict of
    attribute handle and its values.

    Description of argument(s):
    attr_val_table_data     pldmtool output from GetBIOSTable table type AttributeValueTable.

    @return                 Dict of BIOS attribute and its value.

    """
    attr_val_data_dict = {}
    for item in attr_val_table_data:
        attr_handle = re.findall(r'\(.*?\)', item["AttributeNameHandle"])
        attr_name = attr_handle[0][1:-1]

        command = "bios GetBIOSAttributeCurrentValueByHandle -a " + attr_name
        value = pldmtool(command)
        attr_val_data_dict[attr_name] = value["CurrentValue"]
        if not value["CurrentValue"]:
            if 'name' in attr_name:
                attr_val_data_dict[attr_name] = '""'
            elif 'hb_lid_ids' in attr_name:
                attr_val_data_dict[attr_name] = '""'

    return attr_val_data_dict


def GetBIOSAttrDefaultValues(attr_val_table_data):

    """
    From pldmtool GetBIOSTable of type AttributeValueTable get the dict of
    attribute handle and its default attribute values.

    Description of argument(s):
    attr_val_table_data     pldmtool output from GetBIOSTable table type AttributeValueTable.

    @return                 Dict of BIOS attribute and its default attribute value.

    """
    attr_val_data_dict = {}
    for item in attr_val_table_data:
        attr_handle = re.findall(r'\(.*?\)', item["AttributeNameHandle"])
        attr_name = attr_handle[0][1:-1]

        if "DefaultString" in item:
            attr_val_data_dict[attr_name] = item["DefaultString"]
            if not item["DefaultString"]:
                if 'name' in attr_name:
                    attr_val_data_dict[attr_name] = '""'
                elif 'hb_lid_ids' in attr_name:
                    attr_val_data_dict[attr_name] = '""'
        elif "DefaultValue" in item:
            attr_val_data_dict[attr_name] = item["DefaultValue"]
        elif "StringHandle" in item:
            attr_default_value = re.findall(r'\(.*?\)', item["StringHandle"])
            attr_val_data_dict[attr_name] = attr_default_value[0][1:-1]

    return attr_val_data_dict


def GetNewValuesForAllBIOSAttrs(attr_table_data):

    """
    Get a new set of values for all attributes in Attribute Table.

    Description of argument(s):
    attr_table_data         pldmtool output from GetBIOSTable table type AttributeValueTable.

    @return                 Dict of BIOS attribute and new attribute value.

    """
    existing_data = GetBIOSAttrOriginalValues(attr_table_data)
    logger.info(existing_data)
    string_attr_data = GetBIOSStrAndIntAttributeHandles("BIOSString", attr_table_data)
    logger.info(string_attr_data)
    int_attr_data = GetBIOSStrAndIntAttributeHandles("BIOSInteger", attr_table_data)
    logger.info(int_attr_data)
    enum_attr_data = GetBIOSEnumAttributeOptionalValues(attr_table_data)
    logger.info(enum_attr_data)

    attr_random_data = {}
    temp_list = enum_attr_data.copy()
    for attr in enum_attr_data:
        try:
            temp_list[attr].remove(existing_data[attr])
        except ValueError:
            try:
                # The data values have a double quote in them.
                # Eg: '"IBM I"' instead of just 'IBM I'
                data = '"' + str(existing_data[attr]) + '"'
                temp_list[attr].remove(data)
            except ValueError:
                logger.info("Unable to remove the existing value "
                            + str(data) + " from list " + str(temp_list[attr]))
        valid_values = temp_list[attr][:]
        value = random.choice(valid_values)
        attr_random_data[attr] = value.strip('"')
    logger.info("Values generated for enumeration type attributes")

    for attr in string_attr_data:
        # Iterating to make sure we have a different value
        # other than the existing value.
        for iter in range(5):
            random_val = GetRandomBIOSIntAndStrValues(attr, string_attr_data[attr]["MaximumStringLength"])
            if random_val != existing_data[attr]:
                break
        attr_random_data[attr] = random_val.strip('"')
    logger.info("Values generated for string type attributes")

    for attr in int_attr_data:
        for iter in range(5):
            random_val = GetRandomBIOSIntAndStrValues(attr, int_attr_data[attr]["UpperBound"])
            if random_val != existing_data[attr]:
                break
        attr_random_data[attr] = random_val
    logger.info("Values generated for integer type attributes")

    return attr_random_data
