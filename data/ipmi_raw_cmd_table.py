#!/usr/bin/env python3

r"""
IPMI raw commands table:

   - Define IPMI interface index, commands and expected output.

"""

# The currently supported cipher list.
# Refer:
# openbmc/meta-openbmc-machines/meta-openpower/meta-ibm/meta-witherspoon/recipe
# s-phosphor/ipmi/phosphor-ipmi-host/cipher_list.json
valid_ciphers = ['17']
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
    },
    'LAN_Config_Params':
    {
        'Get':
        [
            # raw command, expected output, comment
            "0x0c 0x02",
            "11 02",
            "11 is Parameter revision, 02 is Configuration parameter data e.g. Cipher Suite Entry count",
        ]
    },
    'Payload':
    {
        'Get_Payload_Activation_Status':
        [
            # raw command, expected output(s), comment
            "0x06 0x4a 0x01",
            "01 00 00",
            "1st byte is instance capacity, last two bytes is activation status of instances",
        ],
        'Activate_Payload':
        [
            # raw command, expected output(s), comment
            "0x06 0x48 0x01 0x01 0xc6 0x00 0x00 0x00",
            "00 00 00 00 ff 00 ff 00 6f 02 ff ff",
            "Last two bits are payload vlan number, - FFFFh if VLAN addressing is not used",
        ],
        'Deactivate_Payload':
        [
            # raw command, expected output(s), comment
            "0x06 0x49 0x01 0x01 0x00 0x00 0x00 0x00",
            "",
            "Line feed only",
        ],
        'Get_Payload_Instance_Info':
        [
            # raw command, expected output(s), comment
            "0x06 0x4b 0x01 0x01",
            "00 00 00 00 00 00 00 00 00 00 00 00",
            "When the payload is activated, the first four bytes are the session ID,"
            "otherwise it should be 00."
        ]
    },
    'BIOS_POST_Code':
    {
        'Get':
        [
            # raw command, expected output, comment
            "0x30 0xe9",
            "",
            "Response bytes will vary in length depending on state of system",
            "0x89",
            "error response byte when host is powered off"
        ]
    },
    'Watchdog':
    {
        # Command action type
        'Get':
        [
            # raw command, expected output(s), comment
            "0x06 0x25",
            "05 00 00 00 64 00",
            "don't log bit enabled",
            "85 00 00 00 64 00",
            "don't log bit disabled",
            "05 00 00 00",
            "stop bit stop",
            "45 00 00 00",
            "stop bit resume",
            "01 00 00 00 64 00",
            "timer use FRB2",
            "02 00 00 00 64 00",
            "timer use POST",
            "03 00 00 00 64 00",
            "timer use OS",
            "04 00 00 00 64 00",
            "timer use SMS",
            "05 00 00 00 64 00",
            "timer use OEM",
            "05 00 00 00 64 00",
            "pre-timeout interrupt None",
            "05 20 00 00 64 00",
            "pre-timeout interrupt NMI",
            "05 00 00 00 64 00",
            "timeout action None",
            "05 01 00 00 64 00",
            "timeout action Reset",
            "05 02 00 00 64 00",
            "timeout action PowerDown",
            "05 03 00 00 64 00",
            "timeout action PowerCycle",
            "01 00 00 02",
            "timeout flag FRB2",
            "02 00 00 04",
            "timeout flag POST",
            "03 00 00 08",
            "timeout flag OS",
            "04 00 00 10",
            "timeout flag SMS",
            "05 00 00 20",
            "timeout flag OEM",
            "05 00 00 00 30 35 30 35",
            "Get should return 13.6 seconds",
            "05 00 00 00 ff ff ff ff",
            "Bit 6 not set when timer stopped",
            "0x06 0x25 0x00",
            "Get with one extra byte",
        ],
        'Set':
        [
            # raw command, expected output, comment
            "0x06 0x24 0x05 0x00 0x00 0x00 0x64 0x00",
            "none",
            "don't log bit enabled",
            "0x06 0x24 0x85 0x00 0x00 0x00 0x64 0x00",
            "none",
            "don't log bit disabled",
            "0x06 0x24 0x05 0x00 0x00 0x00 0x35 0x30",
            "none",
            "stop bit stop",
            "0x06 0x24 0x45 0x00 0x00 0x00 0x35 0x30",
            "none",
            "stop bit resume",
            "0x06 0x24 0x01 0x00 0x00 0x00 0x64 0x00",
            "none",
            "timer use FRB2",
            "0x06 0x24 0x02 0x00 0x00 0x00 0x64 0x00",
            "none",
            "timer use POST",
            "0x06 0x24 0x03 0x00 0x00 0x00 0x64 0x00",
            "none",
            "timer use OS",
            "0x06 0x24 0x04 0x00 0x00 0x00 0x64 0x00",
            "none",
            "timer use SMS",
            "0x06 0x24 0x05 0x00 0x00 0x00 0x64 0x00",
            "none",
            "timer use OEM",
            "0x06 0x24 0x05 0x00 0x00 0x00 0x64 0x00",
            "none",
            "pre-timeout interrupt None",
            "0x06 0x24 0x05 0x20 0x00 0x00 0x64 0x00",
            "none",
            "pre-timeout interrupt NMI",
            "0x06 0x24 0x05 0x00 0x00 0x00 0x64 0x00",
            "none",
            "timeout action None",
            "0x06 0x24 0x05 0x01 0x00 0x00 0x64 0x00",
            "none",
            "timeout action Reset",
            "0x06 0x24 0x05 0x02 0x00 0x00 0x64 0x00",
            "none",
            "timeout action PowerDown",
            "0x06 0x24 0x05 0x03 0x00 0x00 0x64 0x00",
            "none",
            "timeout action PowerCycle",
            "0x06 0x24 0x01 0x00 0x00 0x3e 0x01 0x00",
            "none",
            "timeout flag FRB2",
            "0x06 0x24 0x02 0x00 0x00 0x3e 0x01 0x00",
            "none",
            "timeout flag POST",
            "0x06 0x24 0x03 0x00 0x00 0x3e 0x01 0x00",
            "none",
            "timeout flag OS",
            "0x06 0x24 0x04 0x00 0x00 0x3e 0x01 0x00",
            "none",
            "timeout flag SMS",
            "0x06 0x24 0x05 0x00 0x00 0x3e 0x01 0x00",
            "none",
            "timeout flag OEM",
            "0x06 0x24 0x01 0x02 0x00 0x00 0x20 0x00",
            "none",
            "Power down",
            "0x06 0x24 0x01 0x01 0x00 0x00 0x20 0x00",
            "none",
            "Hard reset",
            "0x06 0x24 0x01 0x03 0x00 0x00 0x20 0x00",
            "none",
            "Power cycle",
            "0x06 0x24 0x01 0x00 0x00 0x00 0x20 0x00",
            "none",
            "No action",
            "0x06 0x24 0x05 0x00 0x00 0x3e 0x30 0x35",
            "none",
            "Set for 13.6 seconds",
            "0x06 0x24 0x05 0x00 0x07 0x00 0x50 0x00",
            "none",
            "Pre-timeout interval passes",
            "0x06 0x24 0x05 0x00 0x04 0x00 0x0A 0x00",
            "none",
            "Pre-timeout interval fails",
            "0x06 0x24 0x05 0x00 0x00 0x3e 0xFF 0xFF",
            "none",
            "Bit 6 not set when timer stopped",
            "0x06 0x24 0x05 0x00 0x08 0x00 0x64",
            "none",
            "Set with one less byte",
            "0x06 0x24 0x05 0x00 0x08 0x00 0x64 0x00 0x00",
            "none",
            "Set with one extra byte",
        ],
        'Reset':
        [
            # raw command, expected output, comment
            "0x06 0x22",
            "none",
            "Reset watchdog timer",
            "0x06 0x22 0x00",
            "none",
            "Reset watchdog timer with extra byte",
            "0x06 0x22",
            "none",
            "Reset watchdog timer without initialized watchdog",
        ]
    }
}
