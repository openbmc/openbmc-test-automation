#!/usr/bin/env python

r"""
This module provides some valuable routines for SB verification
"""


class sb_utils(object):

    def __init__(self):
        r"""
        Initialize the bmc_sb_utils object.
        """

    def get_jumper_position(self, in_val):

        out_val = in_val.strip()
        out_val = (bin(int((out_val.split("x")[1]), 16))).split("b")[1]

        # 0 - Jumper off
        # 1 - Jumper On
        return int(out_val[5])

    def get_secureboot_policy(self, in_val):

        out_val = in_val.strip()
        out_val = (bin(int((out_val.split("x")[1]), 16))).split("b")[1]

        # 0 - SecureBoot Off
        # 1 - SecureBoot On
        return int(out_val[4])

    def get_system_jumper_state(self, in_val1, in_val2):

        if in_val1 and in_val2:
            # 1 - Jumpers On
            return "ON"
        else:
            # 0 - Jumpers Off
            return "OFF"

    def get_system_sb_state(self, in_val1, in_val2):

        if in_val1 and in_val2:
            # 1 - SB enabled
            return "ENABLED"
        else:
            # 0 -  SB disabled
            return "DISABLED"
