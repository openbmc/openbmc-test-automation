#!/usr/bin/env python

r"""
PLDM functions.
"""

import re
import var_funcs as vf
import func_args as fa
import bmc_ssh_utils as bsu


def pldmtool(option_string, parse_results=1, **bsu_options):
    r"""
    Run pldmtool on the BMC with the caller's option string and return the result.

    Example:

    ${pldm_results}=  Pldmtool  base GetPLDMTypes
    Rprint Vars  pldm_results

    pldm_results:
      [supported_types]:
        [raw]:
          [0]:                                        0
          [1]:                                        2
          [2]:                                        3
        [text]:
          [0]:                                        base
          [1]:                                        platform
          [2]:                                        bios

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

    if parse_results:
        result = vf.key_value_outbuf_to_dict(stdout)
        if 'supported_types' in result:
            # 'supported types' begins like this:
            # 0(base) 2(platform) 3(bios)
            # Parsing it to look like it does in the example above.
            supported_types = {'raw': [], 'text': []}
            for entry in result['supported_types'].split(" "):
                record = entry.split("(")
                supported_types['raw'].append(record[0])
                supported_types['text'].append(record[1].rstrip(")"))
            result['supported_types'] = supported_types

        elif 'supported_commands' in result:
            commands = result['supported_commands'].split(":")[0].split(" ")
            return commands

        elif 'yyyy-mm-dd_hh' in result:
            # Date & Time :
            # YYYY-MM-DD HH:MM:SS - 2020-02-24 06:44:16
            return result['yyyy-mm-dd_hh'].split(' - ')[1]

        # Simplfying dict output for GetPDR with type PDREntityAssociation.
        # Example :

        # pldmtool platform GetPDR -d 10
        # Entity Association
        # nextRecordHandle: 0
        # responseCount: 56
        # recordHandle: 10
        # PDRHeaderVersion: 1
        # PDRType: 15
        # recordChangeNumber: 0
        # dataLength: 46
        # containerID: 1
        # associationType: Physical
        # containerEntityType: System Board
        # containerEntityInstanceNumber: 1
        # containerEntityContainerID: 0
        # containedEntityCount: 6
        # containedEntityType[1]: Chassis front panel board (control panel)
        # containedEntityInstanceNumber[1]: 1
        # containedEntityContainerID[1]: 1
        # containedEntityType[2]: Chassis front panel board (control panel)
        # containedEntityInstanceNumber[2]: 2
        # containedEntityContainerID[2]: 1
        elif 'containerentitycontainerid' in result:
            dict_data1, dict_data2 = vf.split_dict_on_key('containerentitycontainerid', result)
            return dict_data1

        return result

    return stdout
