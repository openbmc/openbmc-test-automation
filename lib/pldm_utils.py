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
      [request_message]:                              08 01 80 00 04
      [success_in_creating_the_socket]:               RC = 3
      [success_in_connecting_to_socket]:              RC = 0
      [success_in_sending_message_type_as_pldm_to_mctp]:RC = 0
      [write_to_socket_successful]:                   RC = 5
      [total_length]:                                 14
      [loopback_response_message]:                    08 01 80 00 04
      [on_first_recv(),response_==_request]:          RC = 0
      [shutdown_socket_successful]:                   RC = 0
      [response_message]:                             08 01 00 00 04 00 0d 00 00 00 00 00 00 00
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
        # Remove linefeeds following colons.
        stdout = re.sub(":\n", ":", stdout)
        # Remove first line (e.g. "Encode request successfully").
        stdout = re.sub("^.*\\n", "", stdout)
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

        if 'date_&_time' in result:
            return result['yyyy-mm-dd_hh'].split(' - ')[1]

        return result

    return stdout
