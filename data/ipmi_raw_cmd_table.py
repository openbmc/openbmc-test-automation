#!/usr/bin/env python

r"""
IPMI raw commands table:

   - Define IPMI interface index, commands and expected output.

"""

# The currently supported cipher list.
# Refer:
# openbmc/meta-openbmc-machines/meta-openpower/meta-ibm/meta-witherspoon/recipe
# s-phosphor/ipmi/phosphor-ipmi-host/cipher_list.json
valid_ciphers = ['3', '17']
unsupported_ciphers = ['1', '2', '15', '16']

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
            "00 40 02 00",
            "40 is scanning enabled and 02 indicates redundancy enabled",
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
    },
    'SEL_entry':
    {
        'Add':
        [
            # raw command, expected output, comment
            "0x0a 0x44 0x00 0x00 0x02 0x00 0x00 0x00 0x00 0x00 0x00 0x04 0x01 0x17 0x00 0xa0 0x04 0x07",
            "02 00",
            "02 00 is Record ID for added record, LS Byte first",
        ],
        'Reserve':
        [
            # raw command, expected output, comment
            "0x0a 0x42",
            "27 00",
            "27 is Reservation ID, LSB, 00 Reservation ID, MSB ",
        ]
    },
    'Self_Test_Results':
    {
        'Get':
        [
            # raw command, expected output(s), comment
            "0x06 0x04",
            "56 00",
            "56h = Self Test function not implemented in this controller.",
        ]
    },
    'Device GUID':
    {
        'Get':
        [
            # raw command, expected output(s), comment
            "0x06 0x08",
            "01 70 9b ae da 6f dd 9c b4 4c 36 be 66 c8 49 28",
            "Get GUID bytes 1 through 16.",

        ]
    }
}
