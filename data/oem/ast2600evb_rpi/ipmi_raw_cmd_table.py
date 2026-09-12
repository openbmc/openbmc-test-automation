#!/usr/bin/env python3

r"""
IPMI raw commands table for AST2600 EVB+RPI inband tests.

   - Define IPMI interface index, commands and expected output.
   - These commands are specific to the SSIF (System Management Software
     Interface) used in the AST2600 EVB+RPI setup.

SSIF Group Extension identifier: 0x52
NetFn used: 0x2C (Group Extension, IPMI spec Table 5-1)

"""

# SSIF Group Extension identifier byte embedded in every SSIF command.
SSIF_GROUP_EXT = "0x52"

IPMI_RAW_CMD = {
    # ------------------------------------------------------------------ #
    # SSIF Get Manager Certificate Fingerprint                            #
    # NetFn: 0x2C (Group Extension)  Cmd: 0x01                           #
    # Request:  [GroupExt=0x52] [AlgoType=0x01 → SHA-256]                #
    # Response: [GroupExt=0x52] [AlgoType=0x01] [32 SHA-256 bytes]       #
    # ------------------------------------------------------------------ #
    "ssif_certificate_fingerprint": {
        "Get": [
            # raw command
            "0x2c 0x01 0x52 0x01",
            # expected first two bytes of response
            "52 01",
            # First byte 0x52 = group-ext echo; second byte 0x01 = SHA-256
            # algo echo; remaining 32 bytes are the SHA-256 fingerprint.
        ],
    },

    # ------------------------------------------------------------------ #
    # SSIF Get Bootstrap Account Credentials                              #
    # NetFn: 0x2C (Group Extension)  Cmd: 0x02                           #
    # Request:  [GroupExt=0x52] [Mode: 0xA5=enable | 0x00=disable]       #
    # Response: [GroupExt=0x52] [username\x00] [password\x00]            #
    # ------------------------------------------------------------------ #
    "ssif_bootstrap_credentials": {
        "Get_Enabled": [
            # raw command – request credentials, keep bootstrapping enabled
            "0x2C 0x02 0x52 0xA5",
            # expected first byte of response
            "52",
            # 0xA5 requests credentials and keeps Credential Bootstrapping
            # enabled; response contains NULL-terminated username followed
            # by NULL-terminated password.
        ],
        "Get_Disabled": [
            # raw command – request credentials, disable bootstrapping after
            "0x2C 0x02 0x52 0x00",
            # expected first byte of response
            "52",
            # 0x00 requests credentials and disables Credential Bootstrapping
            # after retrieval; response contains NULL-terminated username
            # followed by NULL-terminated password.
        ],
    },
}
