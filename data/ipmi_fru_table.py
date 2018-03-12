#!/usr/bin/env python

r"""
IPMI FRU table:
   - Define IPMI FRU data fields for different components.
"""

# TODO: Disabling board_mfg FRU field as logic needs to be added to test it.
ipmi_fru_dict = {
    "cpu": {
        # "board_mfg_date": "BuildDate",
        "board_mfg": "Manufacturer",
        "board_product": "PrettyName",
        "board_serial": "SerialNumber",
        "board_part_number": "PartNumber"
    },
    "system": {
        "chassis_part_number": "Model",
        "chassis_serial": "SerialNumber"
    },
    "motherboard": {
        "board_mfg": "Manufacturer",
        "board_product": "PrettyName",
        "board_serial": "SerialNumber",
        "board_part_number": "PartNumber"
    },
    "dimm": {
        "product_manufacturer": "Manufacturer",
        "product_name": "PrettyName",
        "product_part_number": "Model",
        "product_version": "Version",
        "product_serial": "SerialNumber"
    },
    "fan": {
        "product_name": "PrettyName"
    },
    "bmc": {
        # "board_mfg_date": "BuildDate",
        "board_mfg": "Manufacturer",
        "board_product": "PrettyName",
        "board_serial": "SerialNumber",
        "board_part_number": "PartNumber"
    },
    "powersupply": {
        # "board_mfg_date": "BuildDate",
        "board_product": "PrettyName",
        "board_serial": "SerialNumber",
        "board_part_number": "PartNumber"
    },
    "gv100card": {
        # "board_mfg_date": "BuildDate",
    }
}

