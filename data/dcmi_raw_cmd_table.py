#!/usr/bin/env python3

r"""
DCMI raw commands table:

   - Define DCMI interface index, commands and expected output.

"""

DCMI_RAW_CMD = {
    # Interface name
    "DCMI":
    {
        "Asset_Tag": [
            # raw command for get asset tag
            "0x2c 0x06 0xdc 0x00",
            # raw command for set asset tag
            "0x2c 0x08 0xdc 0x00",
        ],
    },
}
