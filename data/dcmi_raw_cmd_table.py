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
        "GET_TEMPERATURE_READING": [
            # raw command, inlet temp entity ID, CPU temp entity ID, Baseboard temp entity ID
            "0x2c 0x10 0xdc 0x01",
            "0x40",
            "0x41",
            "0x42",
        ],
        "Asset_Tag": [
            # raw command for get asset tag
            "0x2c 0x06 0xdc 0x00",
            # raw command for set asset tag
            "0x2c 0x08 0xdc 0x00",
        ],
        "SET_DCMI_CONFIG_PARAMETER": {
            "DISCOVERY_CONFIGURATION": {
                "OPTION_12_WITHOUT_RANDOM_BACKOFF": "0x2c 0x12 0xdc 0x02 0x00 0x01",
                "OPTION_60_AND_43_WITHOUT_RANDOM_BACKOFF": "0x2c 0x12 0xdc 0x02 0x00 0x02",
                "OPTION_12_WITH_RANDOM_BACKOFF": "0x2c 0x12 0xdc 0x02 0x00 0x81",
                "OPTION_60_AND_43_WITH_RANDOM_BACKOFF": "0x2c 0x12 0xdc 0x02 0x00 0x82",
            },
        },
        "GET_DCMI_CONFIG_PARAMETER": {
            "DISCOVERY_CONFIGURATION": "0x2c 0x13 0xdc 0x02 0x00"
        },
    },
}
