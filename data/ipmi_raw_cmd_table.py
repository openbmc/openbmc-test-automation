#!/usr/bin/env python3

r"""
IPMI raw commands table:

   - Define IPMI interface index, commands and expected output.

"""

from robot.libraries.BuiltIn import BuiltIn

# The currently supported cipher list.
# Refer:
# openbmc/meta-openbmc-machines/meta-openpower/meta-ibm/meta-witherspoon/recipe
# s-phosphor/ipmi/phosphor-ipmi-host/cipher_list.json
valid_ciphers = ["17"]
unsupported_ciphers = ["1", "2", "15", "16"]

IPMI_RAW_CMD = {
    # Interface name
    "power_supply_redundancy": {
        # Command action type
        "Get": [
            # raw command, expected output(s), comment
            "0x04 0x2d 0x0b",
            "00 00 01 00",
            "Byte position 3rd LSB e.g. 01 indicates disabled",
            "00 00 02 00",
            "Byte position 3rd LSB e.g. 02 indicates enabled",
            "00 40 02 00",
            "40 is scanning enabled and 02 indicates redundancy enabled",
        ],
        "Enabled": [
            # raw command, expected output, comment
            "0x04 0x30 0x0b 0x00 0x00 0x02 0x00 0x00 0x00 0x00 0x00 0x00",
            "none",
            "Enabled nibble position 6th LSB e.g. 0x2",
        ],
        "Disabled": [
            # raw command, expected output, comment
            "0x04 0x30 0x0b 0x00 0x00 0x01 0x00 0x00 0x00 0x00 0x00 0x00",
            "none",
            "Enabled nibble position 6th LSB e.g. 0x1",
        ],
    },
    "power_reading": {
        "Get": [
            # raw command, expected output(s), comment
            "0x2c 0x02 0xdc 0x01 0x01 0x00",
            "dc d5 00 d5 00 d5 00 d5 00 00 00 00 00 00 00 00 00 00",
            "Byte position 2nd LSB e.g. d5 Instantaneous power readings",
        ],
    },
    "conf_param": {
        "Enabled": [
            # raw command, expected output, comment
            "0x2c 0x12 0xdc 0x02 0x00 0x01",
            "dc",
            "Enabled nibble position 6th LSB e.g. 0x01",
        ],
        "Disabled": [
            # raw command, expected output, comment
            "0x2c 0x12 0xdc 0x02 0x00 0x00",
            "dc",
            "Disable nibble position 6th LSB e.g. 0x00",
        ],
    },
    "SEL_entry": {
        "Reserve": [
            # raw command, expected output, comment
            "0x0a 0x42",
            "27 00",
            "27 is Reservation ID, LSB, 00 Reservation ID, MSB ",
        ],
        "Get_SEL_Time": [
            # raw command
            "0x0a 0x48",
        ],
        "Set_SEL_Time": [
            # raw command, expected output(s)
            "0x0a 0x49",
            "rsp=0xd5",
            "not supported in present state",
            "rsp=0xc7",
            "Request data length invalid",
        ],
        "Clear_SEL": [
            # raw command, expected output(s)
            "0x0a 0x47",
            "0x43 0x4c 0x52 0xaa",
            "sel clear",
            "Clearing SEL",
            "rsp=0xc5",
            "Reservation cancelled or invalid",
            "0x43 0x4c 0x52 0x00",
        ],
        "SEL_info": [
            # raw command
            "0x0a 0x40"
        ],
        "Create_SEL": [
            # raw command, expected output, comment
            "0x0a 0x44 0x00 0x00 0x02 0x00 0x00 0x00 0x00",
            "0x04",
            "0x00 0xa0 0x04 0x07",
        ],
        "Get_SEL_Entry": [
            # raw command
            "0x0a 0x43 0x00 0x00",
            "0x00 0xff",
        ],
    },
    "Self_Test_Results": {
        "Get": [
            # raw command, expected output(s), comment
            "0x06 0x04",
            "56 00",
            "56h = Self Test function not implemented in this controller.",
        ]
    },
    "Device GUID": {
        "Get": [
            # raw command, expected output(s), comment
            "0x06 0x08",
            "01 70 9b ae da 6f dd 9c b4 4c 36 be 66 c8 49 28",
            "Get GUID bytes 1 through 16.",
        ]
    },
    "LAN_Config_Params": {
        "Get": [
            # raw command, expected output, comment
            "0x0c 0x02",
            "11 02",
            (
                "11 is Parameter revision, 02 is Configuration parameter data"
                " e.g. Cipher Suite Entry count"
            ),
        ],
        "Set": [
            # raw command, expected output, error response
            "0x0c 0x01",
            "11 00",
            "Unknown (0x82)",
            "Invalid data field in request",
        ],
    },
    "Payload": {
        "Get_Payload_Activation_Status": [
            # raw command, expected output(s), comment
            "0x06 0x4a 0x01",
            "01 00 00",
            (
                "1st byte is instance capacity, last two bytes is activation"
                " status of instances"
            ),
        ],
        "Activate_Payload": [
            # raw command, expected output(s), comment
            "0x06 0x48 0x01 0x01 0xc6 0x00 0x00 0x00",
            "00 00 00 00 ff 00 ff 00 6f 02 ff ff",
            (
                "Last two bits are payload vlan number, - FFFFh if VLAN"
                " addressing is not used"
            ),
        ],
        "Deactivate_Payload": [
            # raw command, expected output(s), comment
            "0x06 0x49 0x01 0x01 0x00 0x00 0x00 0x00",
            "",
            "Line feed only",
        ],
        "Get_Payload_Instance_Info": [
            # raw command, expected output(s), comment
            "0x06 0x4b 0x01 0x01",
            "00 00 00 00 00 00 00 00 00 00 00 00",
            (
                "When the payload is activated, the first four bytes are the"
                " session ID,otherwise it should be 00."
            ),
        ],
        "Get_User_Access_Payload": [
            # raw command,
            "0x06 0x4d"
        ],
        "Set_User_Access_Payload": [
            # raw command,
            "0x06 0x4c"
        ],
        "Get_Channel_Payload_Version": [
            # raw command,
            "0x06 0x4F"
        ],
        "Get_Channel_Payload_Support": [
            # raw command,
            "0x06 0x4E"
        ],
    },
    "BIOS_POST_Code": {
        "Get": [
            # raw command, expected output, comment
            "0x30 0xe9",
            "",
            "Response bytes will vary in length depending on state of system",
            "0x89",
            "error response byte when host is powered off",
        ]
    },
    "Device ID": {
        "Get": [
            # raw command, error response, error code
            "0x06 0x01",
            "Error: Unable to establish IPMI v2 / RMCP+ session",
            "0xc7",
        ]
    },
    "Cold Reset": {
        "reset": [
            # raw command
            "0x06 0x02"
        ]
    },
    "lan_parameters": {
        "get_ip": [
            # raw command
            "0x0c 0x02 0x"
            + BuiltIn().get_variable_value("${CHANNEL_NUMBER}")
            + " 0x03 0 0",
        ],
        "get_ip_src": [
            # raw command
            "0x0c 0x02 0x"
            + BuiltIn().get_variable_value("${CHANNEL_NUMBER}")
            + " 0x04 0 0",
        ],
        "get_dot1q": [
            # raw command
            "0x0c 0x02 0x"
            + BuiltIn().get_variable_value("${CHANNEL_NUMBER}")
            + " 0x14 0 0",
        ],
    },
    "SDR_Info": {
        "get": [
            # raw command
            "0x04 0x20 1",
            # invalid data length extra byte
            "0x04 0x20 0x01 0x00",
            "0x04 0x20 0x00 0x00",
        ],
    },
    "Chassis_status": {
        "get": [
            # raw command
            "0x00 0x01"
        ],
        "get_invalid_length": [
            # raw command, invalid data length extra byte
            "0x00 0x01 0x00"
        ],
    },
    "SEL_Info": {
        "get": [
            # raw command
            "0x0a 0x40"
        ]
    },
    "Watchdog": {
        # Command action type
        "Get": [
            # raw command, expected output(s), comment
            "0x06 0x25",
            "05 00 00 00 64 00",
            "don't log bit enabled",
            "85 00 00 00 64 00",
            "don't log bit disabled",
            "05 00 00 00 64 00",
            "stop bit stop",
            "45 00 00 00 64 00",
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
            "01 00 00 02 00 00",
            "timeout flag FRB2",
            "02 00 00 04 00 00",
            "timeout flag POST",
            "03 00 00 08 00 00",
            "timeout flag OS",
            "04 00 00 10 00 00",
            "timeout flag SMS",
            "05 00 00 20 00 00",
            "timeout flag OEM",
            "05 00 00 00 30 35 30 35",
            "Get should return 13.6 seconds",
            "05 00 00 00 ff ff ff ff",
            "Bit 6 not set when timer stopped",
            "0x06 0x25 0x00",
            "Get with one extra byte",
        ],
        "Set": [
            # raw command, expected output, comment
            "0x06 0x24 0x05 0x00 0x00 0x00 0x64 0x00",
            "none",
            "don't log bit enabled",
            "0x06 0x24 0x85 0x00 0x00 0x00 0x64 0x00",
            "none",
            "don't log bit disabled",
            "0x06 0x24 0x05 0x00 0x00 0x00 0x64 0x00",
            "none",
            "stop bit stop",
            "0x06 0x24 0x45 0x00 0x00 0x00 0x64 0x00",
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
            "0x06 0x24 0x01 0x00 0x00 0x3e 0x00 0x00",
            "none",
            "timeout flag FRB2",
            "0x06 0x24 0x02 0x00 0x00 0x3e 0x00 0x00",
            "none",
            "timeout flag POST",
            "0x06 0x24 0x03 0x00 0x00 0x3e 0x00 0x00",
            "none",
            "timeout flag OS",
            "0x06 0x24 0x04 0x00 0x00 0x3e 0x00 0x00",
            "none",
            "timeout flag SMS",
            "0x06 0x24 0x05 0x00 0x00 0x3e 0x00 0x00",
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
            "0x06 0x24 0x05 0x00 0x00 0x20 0xFF 0xFF",
            "none",
            "Bit 6 not set when timer stopped",
            "0x06 0x24 0x05 0x00 0x08 0x00 0x64",
            "none",
            "Set with one less byte",
            "0x06 0x24 0x05 0x00 0x08 0x00 0x64 0x00 0x00",
            "none",
            "Set with one extra byte",
        ],
        "Reset": [
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
        ],
    },
    "SOL": {
        "Set_SOL": [
            # raw command, expected output(s), comment
            "Invalid value",
            "Valid values are serial, 9.6 19.2, 38.4, 57.6 and 115.2",
        ]
    },
    "Get SDR": {
        "Get": [
            # Get SDR raw command without Reservation ID.
            "0x0a 0x23 0x00 0x00 0x00 0x00 0x00 0xff",
            # Netfunction and cmd.
            "0x0a 0x23",
            # Record ID offset and bytes to read.
            "0x01 0x0f",
            #  Raw command To Get SDR Partial without Reservation ID.
            "0x0a 0x23 0x00 0x00 0x00 0x00 0x01 0x0f",
        ],
    },
    "Get": {
        "POH_Counter": [
            # raw command, error response
            "0x00 0x0f",
            "Error: Unable to establish IPMI v2 / RMCP+ session",
        ]
    },
    "Device_SDR": {
        "Get_Info": [
            # raw command, expected output(s), comment
            "0x04 0x20 0x00",
            "0x04 0x20 0x01",
            "rsp=0xc7",
            "Request data length invalid",
            "rsp=0xd4",
            "Insufficient privilege level",
        ],
        "Get": [
            # raw command, expected output(s), comment
            "0x04 0x21",
            "0x00 0x00 0x00 0xff",
            "rsp=0xc7",
            "Request data length invalid",
        ],
        "Reserve_Repository": [
            # raw command, expected output(s), comment
            "0x04 0x22",
            "rsp=0xc7",
            "Request data length invalid",
            "rsp=0xd4",
            "Insufficient privilege level",
            "Reservation cancelled or invalid",
        ],
    },
    "System_Info": {
        "param0_Set_In_Progress": {
            "Get": [
                # raw command, expected output(s)
                "0x06 0x59 0x00 0x00 0x00 0x00",
                "Request data length invalid",
            ],
            "Set": [
                # raw command, expected output(s)
                "0x06 0x58 0x00",
                "Request data length invalid",
                "Invalid data field in request",
            ],
        },
        "param1_System_Firmware_Version": {
            "Get": [
                # raw command, expected output(s)
                "0x06 0x59 0x00 0x01 0x00 0x00",
                "Request data length invalid",
            ],
            "Set": [
                # raw command, expected output(s)
                "0x06 0x58 0x01 0x00 0x00 0x0e",
                "Invalid data field in request",
            ],
        },
        "param2_System_Name": {
            "Get": [
                # raw command, expected output(s)
                "0x06 0x59 0x00 0x02 0x00 0x00",
                "Request data length invalid",
            ],
            "Set": [
                # raw command, expected output(s)
                "0x06 0x58 0x02 0x00 0x00 0x0e",
                "Invalid data field in request",
            ],
        },
        "param3_Primary_Operating_System_Name": {
            "Get": [
                # raw command, expected output(s)
                "0x06 0x59 0x00 0x03 0x00 0x00",
                "Request data length invalid",
            ],
            "Set": [
                # raw command, expected output(s)
                "0x06 0x58 0x03 0x00 0x00 0x0e",
                "Invalid data field in request",
            ],
        },
        "param4_Operating_System_Name": {
            "Get": [
                # raw command, expected output(s)
                "0x06 0x59 0x00 0x04 0x00 0x00",
                "Request data length invalid",
            ],
            "Set": [
                # raw command, expected output(s)
                "0x06 0x58 0x04 0x00 0x00 0x0e",
                "Invalid data field in request",
            ],
        },
        "param5_Present_OS_Version_number": {
            "Get": [
                # raw command, expected output(s)
                "0x06 0x59 0x00 0x05 0x00 0x00",
                "Request data length invalid",
            ],
            "Set": [
                # raw command, expected output(s)
                "0x06 0x58 0x05 0x00 0x00 0x0e",
                "Invalid data field in request",
            ],
        },
    },
    "system_boot_options": {
        "Get_Boot_Options": [
            # raw command, expected output(s), comment
            "0x00 0x09 0x00 0x00 0x00",
            "0x00 0x09 0x03 0x00 0x00 0x00",
            "Request data length invalid",
        ],
        "Set_Boot_Options": [
            # raw command, expected output(s), comment
            "0x00 0x08 0x00",
            "0x00 0x08 0x03 0x00 0x00",
            "Request data length invalid",
        ],
        "Get_Boot_Flag_Valid_Bit_Clearing": [
            # raw command, expected output(s), comment
            "0x00 0x09 0x03 0x00 0x00",
            "0x00 0x09 0x03 0x00 0x00 0x00",
            "Request data length invalid",
        ],
        "Set_Boot_Flag_Valid_Bit_Clearing": [
            # raw command, expected output(s), comment
            "0x00 0x08 0x03",
            "0x00 0x08 0x03 0x00 0x00",
            "Request data length invalid",
        ],
    },
    "Get Channel Auth Cap": {
        "get": [
            # raw command
            "0x06 0x38",
        ]
    },
    "Cipher Suite": {
        "get": [
            # raw command, supported algorithm
            "0x06 0x54",
            "03 44 81",
            # 03 - HMAC-SHA256
            # 44 - sha256_128
            # 81 - aes_cbc_128
        ]
    },
    "SDR": {
        "Get": [
            # Get SDR raw command without Reservation ID.
            "0x0a 0x23 0x00 0x00 0x00 0x00 0x00 0xff",
            # Netfunction and command.
            "0x0a 0x23",
            # Record ID offset and bytes to read.
            "0x00 0x00 0x01 0x0f",
            #  Raw command To Get SDR Partial without reservation ID.
            "0x0a 0x23 0x00 0x00 0x00 0x00 0x01 0x0f",
        ],
        "Reserve SDR Repository": [
            # raw command, expected output(s), comment
            "0x0a 0x22",
        ],
        "SDR Repository Info": [
            # raw command.
            "0x0a 0x20",
        ],
        "Get SDR allocation Info": [
            # raw command.
            "0x0a 0x21"
        ],
        "Delete SDR": [
            # raw command.
            "0x0a 0x26"
        ],
        "Partially Add SDR": [
            # raw command.
            "0x0a 0x25"
        ],
    },
    "FRU": {
        "Inventory_Area_Info": [
            # raw command, expected output(s), comment
            "0x0a 0x10",
            "Invalid data field in request",
            "Request data length invalid",
        ],
        "Read": [
            # raw command
            "0x0a 0x11",
        ],
        "Write": [
            # raw command
            "0x0a 0x12",
        ],
    },
    "Chassis Capabilities": {
        "Get": [
            # raw command, invalid data length
            "0x00 0x00",
            "0x00 0x00 0x01",
        ]
    },
    "Chassis Control": {
        "power_down": [
            # raw command
            "0x00 0x02 0x00",
            # invalid data length less byte
            "0x00 0x02",
            # invalid data length extra byte
            "0x00 0x02 0x00 0x00",
        ],
        "power_up": [
            # raw command
            "0x00 0x02 0x01",
            # invalid data length less byte
            "0x00 0x02",
            # invalid data length extra byte
            "0x00 0x02 0x01 0x00",
        ],
        "power_cycle": [
            # raw command
            "0x00 0x02 0x02",
            # invalid data length less byte
            "0x00 0x02",
            # invalid data length extra byte
            "0x00 0x02 0x02 0x00",
        ],
        "hard_reset": [
            # raw command
            "0x00 0x02 0x03",
            # invalid data length less byte
            "0x00 0x02",
            # invalid data length extra byte
            "0x00 0x02 0x03 0x00",
        ],
        "pulse_diagnostic_interrupt": [
            # raw command
            "0x00 0x02 0x04",
            # invalid data length less byte
            "0x00 0x02",
            # invalid data length extra byte
            "0x00 0x02 0x04 0x00",
        ],
        "initiate_soft_shutdown": [
            # raw command
            "0x00 0x02 0x05",
            # invalid data length less byte
            "0x00 0x02",
            # invalid data length extra byte
            "0x00 0x02 0x05 0x00",
        ],
    },
}
