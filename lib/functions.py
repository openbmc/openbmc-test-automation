#!/usr/bin/env python3

r"""
Provide useful python functions for basic data manipulation
"""

import string


def fetch_date(date):
    # Removes prefix 0 in a date in given date
    date = date.lstrip("0")
    return date


def fetch_added_sel_date(entry):
    # Split Date with | and join with space
    temp = entry.split(" | ")
    date = temp[1] +" "+ temp[2]
    print(date)
    return date


def split_list_with_index(listx,n):
    # To split every n characters and forms an element for every nth index
    n = int(n)
    data =  [listx[index : index + n] for index in range(0, len(listx), n)]
    return data


def prefix_bytes(listx):
    # prefixes byte strings in list
    listy = []
    for l in listx:
        l = "0x"+ l
        listy.append(l)
    return listy


def remove_whitespace(instring):
    # Removes the white spaces around the string
    return instring.strip()


def zfill_data(data, num):
    # zfill() method adds zeros (0) at the beginning of the string, until it reaches the specified length.
    # Usage : ${anystr}=  Zfill Data  ${data}  num
    # Example : Binary of one Byte has 8 bits - xxxx xxxx
    # Consider ${binary} has only 3 bits after converting from Hexadecimal/decimal to Binary
    # Say ${binary} = 110 then,
    # ${binary}=  Zfill Data  ${binary}  8
    # Now ${binary} will be 0000 0110

    return data.zfill(int(num))
