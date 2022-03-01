#!/usr/bin/env python3

r"""
Provide useful python functions for basic data manipulation
"""

import string


def zfill_data(data, num):
    # zfill() method adds zeros (0) at the beginning of the string, until it reaches the specified length.
    # Usage : ${anystr}=  Zfill Data  ${data}  num
    # Example : Binary of one Byte has 8 bits - xxxx xxxx
    # Consider ${binary} has only 3 bits after converting from Hexadecimal/decimal to Binary
    # Say ${binary} = 110 then,
    # ${binary}=  Zfill Data  ${binary}  8
    # Now ${binary} will be 0000 0110

    return data.zfill(int(num))
