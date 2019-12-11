#!/usr/bin/env python

r"""
PLDM generic functions.

"""

import var_funcs as vf
import bmc_ssh_utils as bsu


def get_pldm_output(pldm_parm_string=""):
    r"""
    Get pldmtool command output and return as a dictionary.

    Example:
    pldm_output = get_pldm_output()
    print_vars(pldm_output)

    pldm_output:
      [encode_request_successfully]:
      [request_message]:                                  08 01 80 00 04
      [success_in_creating_the_socket]:                   RC = 3
      [success_in_connecting_to_socket]:                  RC = 0
      [success_in_sending_message_type_as_pldm_to_mctp]:  RC = 0
      [write_to_socket_successful]:                       RC = 5
      [total_length]:                                     5
      [loopback_response_message]:                        08 01 80 00 04
      [on_first_recv(),response_==_request]:              RC = 0
      [shutdown_socket_successful]:                       RC = 0
      [response_message]:                                 08 01 00 00 04 00 0d 00 00 00 00 00 00 00
      [supported_types:                                   0(base) 2(platform) 3(bios)

    Description of argument(s):
    pldm_parm_string  A string containing valid pldm command parms (e.g.
                    "base GetPLDMVersion").
    """

    stdout, stderr, rc = bsu.bmc_execute_command("pldmtool " + pldm_parm_string)
    return vf.key_value_outbuf_to_dict(stdout)

