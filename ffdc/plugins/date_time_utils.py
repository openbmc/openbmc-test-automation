#!/usr/bin/env python3

r"""
This module contains functions having to do with date time filter.
"""

from datetime import datetime


def convert_string_dateime(date_str, date_format, desired_format):
    r"""
    Convert a date time string to the desired format.

    This function converts a date time string to the desired format.
    The function takes the date_str argument, which can be a single date time
    string or a list of date time strings.

    The function also accepts date_format and desired_format arguments, which
    specify the input date time pattern and the desired output format,
    respectively.

    The function returns a list of date time strings in the desired format.

    Parameters:
        date_str (str or list): A date time string or a list of date time
                                strings.
        date_format (str):      The date time pattern of the input string(s).
        desired_format (str):   The desired output format for the date time
                                strings.

    Returns:
        list: A list of date time strings in the desired format.
    """
    if isinstance(date_str, list):
        tmp_date = []
        for date in date_str:
            tmp_date.append(
                datetime.strptime(date, date_format).strftime(desired_format)
            )
        return tmp_date
    else:
        return datetime.strptime(date_str, date_format).strftime(
            desired_format
        )
