#!/usr/bin/env python

r"""
IPMI raw commands table:

   - Define IPMI interface index, commands and expected output.

"""

# The currently supported cipher level list.
# Refer:
# openbmc/meta-openbmc-machines/meta-openpower/meta-ibm/meta-witherspoon/recipe
# s-phosphor/ipmi/phosphor-ipmi-host/cipher_list.json
valid_cipher_list = [3, 17]
unsupported_cipher_list = [1, 2, 15, 16]

IPMI_RAW_CMD = {
    # Interface name
    'power_supply_redundancy':
    {
        # Command action type
        'Get':
        [
            # raw command, expected output(s), comment
            "0x04 0x2d 0x0b",
            "00 00 01 00",
            "Byte position 3rd LSB e.g. 01 indicates disabled",
            "00 00 02 00",
            "Byte position 3rd LSB e.g. 02 indicates enabled",
        ],
        'Enabled':
        [
            # raw command, expected output, comment
            "0x04 0x30 0x0b 0x00 0x00 0x02 0x00 0x00 0x00 0x00 0x00 0x00",
            "none",
            "Enabled nibble position 6th LSB e.g. 0x2",
        ],
        'Disabled':
        [
            # raw command, expected output, comment
            "0x04 0x30 0x0b 0x00 0x00 0x01 0x00 0x00 0x00 0x00 0x00 0x00",
            "none",
            "Enabled nibble position 6th LSB e.g. 0x1",
        ],
    },
    'power_reading':
    {
        'Get':
        [
            # raw command, expected output(s), comment
            "0x2c 0x02 0xdc 0x01 0x01 0x00",
            "dc d5 00 d5 00 d5 00 d5 00 00 00 00 00 00 00 00 00 00",
            "Byte position 2nd LSB e.g. d5 Instantaneous power readings",
        ],
    },
    'conf_param':
    {
        'Enabled':
        [
            # raw command, expected output, comment
            "0x2c 0x12 0xdc 0x02 0x00 0x01",
            "dc",
            "Enabled nibble position 6th LSB e.g. 0x01",
        ],
        'Disabled':
        [
            # raw command, expected output, comment
            "0x2c 0x12 0xdc 0x02 0x00 0x00",
            "dc",
            "Disable nibble position 6th LSB e.g. 0x00",
        ]
    }
}
