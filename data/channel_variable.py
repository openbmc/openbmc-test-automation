#!/usr/bin/python

r"""
Contains channel-related constants.
"""

medium_type_ipmi_conf_map = {
    "reserved": "reserved",
    "IPMB (I2C)": "ipmb",
    "ICMB v1.0": "icmb-v1.0",
    "ICMB v0.9": "icmb-v0.9",
    "802.3 LAN": "lan-802.3",
    "Serial/Modem": "serial",
    "Other LAN": "other-lan",
    "PCI SMBus": "pci-smbus",
    "SMBus v1.0/v1.1": "smbus-v1.0",
    "SMBus v2.0": "smbus-v2.0",
    "USB 1.x": "usb-1x",
    "USB 2.x": "usb-2x",
    "System Interface": "system-interface"
}


protocol_type_ipmi_conf_map = {
    "reserved": "na",
    "IPMB-1.0": "ipmb-1.0",
    "ICMB-1.0": "icmb-2.0",
    "reserved": "reserved",
    "IPMI-SMBus": "ipmi-smbus",
    "KCS": "kcs",
    "SMIC": "smic",
    "BT-10": "bt-10",
    "BT-15": "bt-15",
    "TMode": "tmode",
    "OEM 1": "oem",
}


disabled_ipmi_conf_map = {
    "disabled": "True",
    "enabled": "False",
}


access_mode_ipmi_conf_map = {
    "disabled": "disabled",
    "pre-boot only": "pre-boot",
    "always available": "always_available",
    "shared": "shared",
}
