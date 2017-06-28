#!/usr/bin/env python


r"""
This module contains json functions to compare two JSON files.
"""

import os
import json


###############################################################################
def json_reorder(jdata):
    r"""
     Internal utility (called by json_file_diff_check) which sorts a
     JSON data structure.  Since JSON structrues are dictionaries which
     contain lists which in turn contain dictionries which contain lists
     which contain...repeat until we get to a leaf node, recursion is used
     here along with sorted().

     Description of argument(s):
     jdata             JSON data structure to sort, usually the
                       result of a json.load.

     Returns
     A data structure which is a sorted copy of the input structure.
     Still in JSON format.
    """

    if isinstance(jdata, dict):
        return sorted((k, json_reorder(v)) for k, v in jdata.items())
    elif isinstance(jdata, list):
        return sorted(json_reorder(item) for item in jdata)
    else:
        # pprint(jdata)   # we are at leaf node.  print the leaf
        return jdata
###############################################################################


###############################################################################
def json_file_diff_check(initial_json_file, subsequent_json_file):
    r"""
     Compares the contents of two files which contain JSON formatted data.
     Comparison checking is independent of the order of entries in the two files.
     That is, the data order in each does not have to be the same.

     We might want to snapshot a system's inventory in JSON format
     at the beginning of tests and again at the end of tests,
     then call this function to see if anything changed.

     Description of argument(s):
     initial_json_file        Name and path of text file containing JSON formated data.
     subsequent_json_file     Name and path of file to compare to the initial file.

     Returns
     0 if both files contain the same information.
     1 if both files do not contain the same information.
     2 is there is a problem opening or reading one or both of the input files.

     Exmple:
     from json_utils import  json_file_diff_check
     file1=sys.argv[1]
     file2=sys.argv[2]
     rc=json_file_diff_check(file1,file2)
     print rc
    """

    if (os.path.exists(initial_json_file)
            and os.path.exists(subsequent_json_file)):
        with open(initial_json_file, 'r') as f:
            try:
                initial = json.load(f)
            except BaseException:
                f.close()
                return 2   # problem reading file
            else:
                f.close()

        with open(subsequent_json_file, 'r') as g:
            try:
                subsequent = json.load(g)
            except BaseException:
                f.close()
                return 2  # problem reading file
            else:
                g.close()

        # must have more than a trivial number of bytes and must compare
        if ((len(initial) > 0) and (json_reorder(
                initial) == json_reorder(subsequent))):
            return 0
        else:
            return 1
    else:
        return 2  # os.path does not exist for one or both input files
###############################################################################
