#!/usr/bin/env python

r"""
PLDM functions.
"""

import re
import var_funcs as vf
import func_args as fa
import bmc_ssh_utils as bsu
import json


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

     pldmtool base GetTID
     {
         "Response": 1
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
    return json.loads(stdout)


def GenerateBIOSAttrHandleValueDict(attr_val_table_data):
    """
    From pldmtool bios GetBIOSTable of AttributeValueTable generate dictionary of
    for bios attribute and its value.

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
                             },
                             {
                                  "AttributeHandle": 26,
                                  "AttributeNameHandle": "28(pvm_fw_boot_side)",
                                  "AttributeType": "BIOSEnumeration",
                                  "NumberOfPossibleValues": 2,
                                  "PossibleValueStringHandle[0]": "11(Perm)",
                                  "PossibleValueStringHandle[1]": "15(Temp)",
                                  "NumberOfDefaultValues": 1,
                                  "DefaultValueStringHandleIndex[0]": 1,
                                  "StringHandle": "15(Temp)"
                             }]

    @return                  Dictionary of bios attribute and its value.
                             e.g. {
                                   'pvm_pcie_error_inject': ['Disabled', 'Enabled'],
                                   'pvm-fw-boot-side': ['Perm', 'Temp']
                                  }
    """

    attr_val_data_dict = {}
    for item in attr_val_table_data:
        for attr in item:
            if (attr == "NumberOfPossibleValues"):
                value_list = []
                for i in range(0, int(item[attr])):
                    attr_values = item["PossibleValueStringHandle[" + str(i) + "]"]
                    value = re.findall(r'\(.*?\)', attr_values)
                    if value:
                        value = value[0][1:-1]
                        if ' ' in value:
                            value = '"' + value + '"'
                        value_list.append(value)

                    else:
                        value_list.append('')

                attr_handle = re.findall(r'\(.*?\)', item["AttributeNameHandle"])
                attr_val_data_dict[attr_handle[0][1:-1]] = value_list
    return attr_val_data_dict
