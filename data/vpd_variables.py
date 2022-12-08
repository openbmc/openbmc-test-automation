#!/usr/bin/env python3

r"""
Contains VPD related constants.
"""

VPD_DETAILS = {
    "/system/chassis/motherboard": {
        "type": "xyz.openbmc_project.Inventory.Item.Board.Motherboard"
    },
    "/system/chassis/motherboard/base_op_panel_blyth": {
        "type": "xyz.openbmc_project.Inventory.Item.Panel"
    },
    "/system/chassis/motherboard/ebmc_card_bmc": {
        "type": "xyz.openbmc_project.Inventory.Item.Bmc"
    },
    "/system/chassis/motherboard/lcd_op_panel_hill": {
        "type": "xyz.openbmc_project.Inventory.Item.Panel"
    },
    "/system/chassis/motherboard/tpm_wilson": {
        "type": "xyz.openbmc_project.Inventory.Item.Tpm"
    },
    "/system/chassis/motherboard/vdd_vrm0": {
        "type": "xyz.openbmc_project.Inventory.Item.Vrm"
    },
    "/system/chassis/motherboard/vdd_vrm1": {
        "type": "xyz.openbmc_project.Inventory.Item.Vrm"
    }
}
