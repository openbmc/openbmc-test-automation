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
    },
}
