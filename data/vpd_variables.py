#!/usr/bin/python

r"""
Contains VPD related constants.
"""

VPD_DETAILS = {
    "/system/chassis/motherboard": {
        "CC": "2E2D",
        "DR": "SYSTEM BACKPLANE",
        "FN": "F191014",
        "LocationCode": "U78DA.ND1.       -P0",
        "PN": "PN12345",
        "SN": "YL2E2D010000",
        "type": "xyz.openbmc_project.Inventory.Item.Board.Motherboard"
    },
    "/system/chassis/motherboard/base_op_panel_blyth": {
        "CC": "6B85",
        "DR": "CEC OP PANEL    ",
        "FN": "F191014",
        "LocationCode": "U78DA.ND1.       -D0",
        "PN": "PN12345",
        "SN": "YL6B85010000",
        "type": "xyz.openbmc_project.Inventory.Item.Panel"
    },
    "/system/chassis/motherboard/ebmc_card_bmc": {
        "CC": "6B58",
        "DR": "EBMC            ",
        "FN": "F191014",
        "LocationCode": "U78DA.ND1.       -P0-C5",
        "PN": "PN12345",
        "SN": "YL6B58010000",
        "type": "xyz.openbmc_project.Inventory.Item.Bmc"
    },
    "/system/chassis/motherboard/lcd_op_panel_hill": {
        "CC": "6B86",
        "DR": "CEC OP PANEL LCD",
        "FN": "F191014",
        "LocationCode": "U78DA.ND1.       -D1",
        "PN": "PN12345",
        "SN": "YL6B86010000",
        "type": "xyz.openbmc_project.Inventory.Item.Panel"
    },
    "/system/chassis/motherboard/tpm_wilson": {
        "CC": "6B59",
        "DR": "TPM CARD        ",
        "FN": "F191014",
        "LocationCode": "U78DA.ND1.       -P0-C22",
        "PN": "PN12345",
        "SN": "YL6B59010000",
        "type": "xyz.openbmc_project.Inventory.Item.Tpm"
    },
    "/system/chassis/motherboard/vdd_vrm0": {
        "CC": "2E32",
        "DR": "CPU POWER CARD  ",
        "FN": "F190827",
        "LocationCode": "U78DA.ND1.       -P0-C14",
        "PN": "PN12345",
        "SN": "YL2E32010000",
        "type": "xyz.openbmc_project.Inventory.Item.Vrm"
    },
    "/system/chassis/motherboard/vdd_vrm1": {
        "CC": "2E32",
        "DR": "CPU POWER CARD  ",
        "FN": "F190827",
        "LocationCode": "U78DA.ND1.       -P0-C23",
        "PN": "PN12345",
        "SN": "YL2E32010000",
        "type": "xyz.openbmc_project.Inventory.Item.Vrm"
    }
}
