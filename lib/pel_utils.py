#!/usr/bin/env python

r"""
PEL functions.
"""

import func_args as fa
import bmc_ssh_utils as bsu
import json


def peltool(option_string, parse_json=True, **bsu_options):
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
    option_string                   A string of options which are to be processed by the peltool command.
    parse_json                      Indicates that the raw JSON data should parsed into a list of
                                    dictionaries.
    bsu_options                     Options to be passed directly to bmc_execute_command. See its prolog for
                                    details.
    """

    bsu_options = fa.args_to_objects(bsu_options)
    out_buf, stderr, rc = bsu.bmc_execute_command('peltool ' + option_string, **bsu_options)
    if parse_json:
        try:
            return json.loads(out_buf)
        except json.JSONDecodeError:
            return {}
    return out_buf
