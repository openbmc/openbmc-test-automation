#!/usr/bin/env python3

r"""
DCMI raw commands table:

   - Define DCMI interface index, commands and expected output.

"""

DCMI_RAW_CMD = {
    # Interface name
    "DCMI": {
        "Get_DCMI_Capabilities_Info": [
            # raw command.
            "0x2c 0x01 0xdc 0x01"
        ],
        "Get_Power_Reading": [
            # raw command, invalid request data. expected error code
            "0x2c 0x02 0xdc 0x01 0x00 0x00",
            "0x2c 0x02 0xdc 0x01 0x00 0x00 0x00 0x00",
            "0x2c 0x02 0xdc 0x04 0x00 0x00",
            "0xc7",
            "0xcc",
        ],
    },
}