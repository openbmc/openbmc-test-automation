#!/usr/bin/env python3

r"""
Provide useful python functions for basic data manipulation
"""

import string


def identify_threshold(thresh, thresholds):
    # Gets Threshold from Sensor list
    # If the thresholds are [ 1, 2, 3, 4] then the new thresholds are [ 101, 102, 103, 104 ]
    # If the threshold has 'na' the same will be appended to new list
    # thresholds are - Higher and Lower of critical and non-critical values
    n=100
    newthresh=[]
    for t in thresh:
       t = t.strip()
       if t == 'na':
          newthresh.append('na')
       else:
          x = int(float(t)) + n
          newthresh.append(x)
          n = n + 100
    dict_thresh = dict(zip(thresholds, newthresh))
    return newthresh, dict_thresh


def remove_whitespace(instring):
    # Removes the white spaces around the string
    return instring.strip()
