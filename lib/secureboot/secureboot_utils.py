#!/usr/bin/env python

r"""
This module provides some valuable routines for Secure Boot verification
"""

from robot.libraries.BuiltIn import BuiltIn


class secureboot_utils(object):

    def get_jumper_position(self, cfam_val):
        r"""
        Analyze cfam 2801 value and return jumper position.

        Description of argument(s):
        cfam_val  The cfam value to be analyzed.
        This value would typically be obtained reading CFAM 2801
        (e.g. 0x94c00000).
        """

        cfam_val = cfam_val.strip()

        # Coneversion to binary
        bin_val = (bin(int((cfam_val.split("x")[1]), 16))).split("b")[1]

        # 0 - Jumper off
        # 1 - Jumper On
        return int(bin_val[5])

    def get_secureboot_policy(self, cfam_val):
        r"""
        Analyze cfam 2801 value and return secureboot policy.

        Description of argument(s):
        cfam_val  The cfam value to be analyzed.
        This value would typically be obtained reading CFAM 2801
        (e.g. 0x94c00000).
        """

        cfam_val = cfam_val.strip()

        # Coneversion to binary
        bin_val = (bin(int((cfam_val.split("x")[1]), 16))).split("b")[1]

        # 0 - SecureBoot Enabled
        # 1 - SecureBoot Disabled
        return int(bin_val[4])

    def get_system_jumper_state(self, jumper_bit_p0, jumper_bit_p1):
        r"""
        Logical AND of returned jumper bit values for processor chip p0 and p1
        and return jumper state based on the condition.

        Description of argument(s):
        jumper_bit_p0  Jumper positiion bit value for p0
        jumper_bit_p1  Jumper positiion bit value for p1
        """

        if jumper_bit_p0 and jumper_bit_p1:
            # 1 - Jumpers On
            return "ON"
        else:
            # 0 - Jumpers Off
            return "OFF"

    def get_system_sb_state(self, sb_bit_p0, sb_bit_p1):
        r"""
        Logical AND of returned secureboot policy bit values for processor
        chip p0 and p1 and return secureboot state based on the condition

        Description of argument(s):
        sb_bit_p0  Jumper positiion bit value for p0
        sb_bit_p1  Jumper positiion bit value for p1
        """

        if sb_bit_p0 and sb_bit_p1:
            # 1 - SB enabled
            return "ENABLED"
        else:
            # 0 -  SB disabled
            return "DISABLED"
