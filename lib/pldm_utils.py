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
