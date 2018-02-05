#!/usr/bin/env python

r"""
IPMI raw commands table

   - Defines IPMI interface index, commands and expected output.

"""

IPMI_RAW_CMD = {
    # Interface name
    'power_supply_redundancy':
    {
        # Cmd action type
        'Get':
        [
            # raw cmd , expected output(s) , comment
            "0x04 0x2d 0x0b",
            "00 00 01 00",
            "Byte position 3'rd LSB i.e. 01 indicates disabled",
            "00 00 02 00",
            "Byte position 3'rd LSB i.e. 02 indicates enabled",
        ],
        'Enabled':
        [
            # raw cmd , expected output , comment
            "0x04 0x30 0x0b 0x00 0x00 0x02 0x00 0x00 0x00 0x00 0x00 0x00",
            "none",
            "Enabled nibble position 6'th LSB i.e. 0x2",
        ],
        'Disabled':
        [
            # raw cmd , expected output , comment
            "0x04 0x30 0x0b 0x00 0x00 0x01 0x00 0x00 0x00 0x00 0x00 0x00",
            "none",
            "Enabled nibble position 6'th LSB i.e. 0x1",
        ],
    }
}
