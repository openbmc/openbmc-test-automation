#!/usr/bin/env python3

r"""
This module provides some functions for Secure Boot verification.
"""

import bmc_ssh_utils as bsu
import var_funcs as vf
from robot.libraries.BuiltIn import BuiltIn


# Define 'constant' functions.
def secure_boot_mask():

    return 0x08000000


def jumper_mask():

    return 0x04000000


class secureboot(object):

    def get_secure_boot_info(self, quiet=None):
        r"""
        Get secure-boot information and return it as a tuple consisting of
        num_procs, secure_boot, jumper.

        num_procs is the number of processors containing the information.

        secure_boot will be set to True if each and every register value
        in question has its secureboot bit set (Bit 4).

        jumper will be set to True if each and every register value
        in question has its jumper bit set (Bit 5).

        Description of argument(s):
        quiet                           See shell_cmd for details.
        """

        cmd_buf = "pdbg -d p9w -a getcfam 0x2801"
        out_buf, stderr, rc = bsu.bmc_execute_command(cmd_buf, quiet=quiet)

        # Convert result to a dictionary with one key for each processor:
        # result:
        #   [p0:0x2801]:               0x80c00002
        #   [p1:0x2801]:               0x90c00002
        result = vf.key_value_outbuf_to_dict(out_buf, delim="=")

        num_procs = len(result)
        # Initialize values to True.
        secure_boot = True
        jumper = True

        for key, value in result.items():
            # Convert hex string to int.
            reg_value = int(value, 16)
            if not reg_value & secure_boot_mask():
                secure_boot = False
            if not reg_value & jumper_mask():
                jumper = False

        return num_procs, secure_boot, jumper
