#!/usr/bin/env python3

r"""
DCMI raw commands table:

   - Define DCMI interface index, commands and expected output.

"""

DCMI_RAW_CMD = {
    # Interface name
    "DCMI": {
        "Asset_Tag": [
            # raw command, inlet temp entity ID, CPU temp entity ID, Baseboard temp entity ID
            '0x2c 0x10 0xdc 0x01',
            '0x40',
            '0x41',
            '0x42',
        ],
    },
}