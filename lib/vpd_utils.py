#!/usr/bin/env python3

r"""
VPD functions.
"""

import func_args as fa
import bmc_ssh_utils as bsu
import json


def vpdtool(option_string, **bsu_options):
    r"""
    Run vpdtool on the BMC with the caller's option string and return the result.

    Example:

    ${vpd_results}=  vpd-tool -i
    Rprint Vars  vpd_results

    vpd_results:
      [/system/chassis/motherboard]:
        [PN]:                                         PN12345
        [SN]:                                         YL2E2D010000
        [LocationCode]:                               U78DA.ND1.       -P0
        [CC]:                                         2E2D
        [DR]:                                         SYSTEM BACKPLANE
        [FN]:                                         F191014
        [type]:                                       xyz.openbmc_project.Inventory.Item.Board.Motherboard
      [/system/chassis/motherboard/ebmc_card_bmc]:
        [PN]:                                         PN12345
        [SN]:                                         YL6B58010000
        [LocationCode]:                               U78DA.ND1.       -P0-C5
        [CC]:                                         6B58
        [DR]:                                         EBMC
        [FN]:                                         F191014
        [type]:                                       xyz.openbmc_project.Inventory.Item.Bmc

    Description of argument(s):
    option_string                   A string of options which are to be processed by the vpd-tool command.
    bsu_options                     Options to be passed directly to bmc_execute_command. See its prolog for
                                    details.
    """

    bsu_options = fa.args_to_objects(bsu_options)
    out_buf, stderr, rc = bsu.bmc_execute_command('vpd-tool ' + option_string, **bsu_options)

    # Only return output if its not a VPD write command.
    if '-w' not in option_string:
        out_buf = json.loads(out_buf)
        if '-r' in option_string:
            return out_buf
        else:
            return out_buf[0]
