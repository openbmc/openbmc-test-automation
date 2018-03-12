#!/usr/bin/env python

r"""
IPMI FRU table:
   - Define IPMI FRU data fields for different components.
"""

ipmi_fru_dict = {
    "cpu": [
        "Board Mfg Date",
        "Board Mfg",
        "Board Product",
        "Board Serial",
        "Board Part Number"
    ],
    "system": [
        "Chassis Type",
        "Chassis Part Number",
        "Chassis Serial",
        "Board Mfg Date",
        "Board Mfg",
        "Board Product",
        "Board Serial",
        "Board Part Number"
    ],
    "dimm": [
        "Product Manufacturer",
        "Product Name",
        "Product Part Number",
        "Product Version",
        "Product Serial"
    ],
    "fan": [
        "Product Name"
    ],
    "bmc": [
        "Board Mfg Date",
        "Board Mfg",
        "Board Product",
        "Board Serial",
        "Board Part Number"
    ],
    "powersupply": [
        "Board Mfg Date",
        "Board Product",
        "Board Serial",
        "Board Part Number"
    ]
}

