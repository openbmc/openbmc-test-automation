#!/usr/bin/env python

r"""
This module contains functions which pertain to device.
"""

import bmc_ssh_utils as bsu
import gen_print as gp
import json


def get_device_id_config():
    r"""
    Get the device id config data and return as a dictionary.

    Example:

    dev_id_config =  get_device_id_config()
    print_vars(dev_id_config)

    dev_id_config:
        [manuf_id]:            7244
        [addn_dev_support]:     141
        [prod_id]:            16976
        [aux]:                    0
        [id]:                    32
        [revision]:             129
    """
    stdout, stderr, rc = bsu.bmc_execute_command("cat /usr/share/ipmi-providers/dev_id.json")

    return json.loads(stdout)


def get_device_revision(structure):
    r"""
    Parse and return Device Revision.

    Reference IPMI specification v2.0 "Get Device ID Command"

    [7]   1 = device provides Device SDRs
          0 = device does not provide Device SDRs
    [6:4] reserved. Return as 0.
    [3:0] Device Revision, binary encoded.
    """

    devRevMask = 0x0F
    revision = structure['revision'] & devRevMask

    return revision
