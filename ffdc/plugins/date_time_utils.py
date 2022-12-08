#!/usr/bin/env python3

r"""
This module contains functions having to do with date time filter.
"""

from datetime import datetime


def convert_string_dateime(date_str, date_format, desired_format):
    r"""
    Return a date time formatted from a string datetime.

    Description of arguments(s):
    date_str            Date time string e.g 2021072418161
                        or list ["2021072418161", "20210723163401"]
    date_format         Date time pattern of the string date time
                        e.g '%Y%m%d%H%M%S'
    desired_format      User define format e.g '%m/%d/%Y - %H:%M:%S'
    """

    if isinstance(date_str, list):
        tmp_date = []
        for date in date_str:
            tmp_date.append(datetime.strptime(date, date_format).strftime(desired_format))
        return tmp_date
    else:
        return datetime.strptime(date_str, date_format).strftime(desired_format)
