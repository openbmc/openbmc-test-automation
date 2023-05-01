#!/usr/bin/env python3

r"""
DCMI raw commands table:

   - Define DCMI interface index, commands and expected output.

"""

DCMI_RAW_CMD = {
    # Interface name
    "DCMI": {
        "MANAGEMENT_CONTROLLER_IDENTIFIER_STRING": {
            "GET": "0x2c 0x09 0xdc 0x00 0x10",
            "SET": "0x2c 0x0a 0xdc 0x00",
        },
        "Asset_Tag": [
            # raw command for get asset tag
            "0x2c 0x06 0xdc 0x00",
            # raw command for set asset tag
            "0x2c 0x08 0xdc 0x00",
        ],
    },
}
