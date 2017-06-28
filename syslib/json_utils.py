#!/usr/bin/env python


r"""
This module contains json functions to compare two JSON files.
"""

import os
import json
try:
    from robot.libraries.BuiltIn import BuiltIn
except ImportError:
    pass


# Success return code
FILES_MATCH = 0

# Failure return codes
FILES_DO_NOT_MATCH = 2
INPUT_FILE_DOES_NOT_EXIST = 3
IO_EXCEPTION_READING_FILE = 4
INPUT_FILE_MALFORMED = 5


###############################################################################
def json_reorder(jdata):
    r"""
     Function to sort JSON data structure.

     Description of argument(s):
     jdata             JSON data structure to sort, usually the
                       result of a json.load.

     Returns
     A data structure which is a sorted copy of the input structure.
    """

    if isinstance(jdata, dict):
        return sorted((k, json_reorder(v)) for k, v in jdata.items())
    elif isinstance(jdata, list):
        return sorted(json_reorder(item) for item in jdata)
    # we are at a leaf node.   Return the leaf
    else:
        return jdata
###############################################################################


###############################################################################
def json_file_diff_check(initial_json_file, subsequent_json_file):
    r"""
     Compares the contents of two files which contain JSON formatted data.
     Comparison checking is independent of the order of entries in the two files.
     That is, the data order in each does not have to be the same.

     Description of argument(s):
     initial_json_file     Name and path of file containing JSON formated data.
     subsequent_json_file  Name and path of file to compare to the initial file.

     Returns
     0 if both files contain the same information.
     2 if FILES_DO_NOT_MATCH.
     3 if INPUT_FILE_DOES_NOT_EXIST.
     4 if IO_EXCEPTION_READING_FILE.
     5 if INPUT_FILE_MALFORMED.
    """

    if (os.path.exists(initial_json_file)
            and os.path.exists(subsequent_json_file)):
        with open(initial_json_file, 'r') as f:
            try:
                initial = json.load(f)
            except IOError:
                f.close()
                return IO_EXCEPTION_READING_FILE
            except ValueError:
                f.close()
                return INPUT_FILE_MALFORMED
            else:
                f.close()

        with open(subsequent_json_file, 'r') as g:
            try:
                subsequent = json.load(g)
            except IOError:
                g.close()
                return IO_EXCEPTION_READING_FILE
            except ValueError:
                f.close()
                return INPUT_FILE_MALFORMED
            else:
                g.close()

        # must have more than a trivial number of bytes and must compare
        if ((len(initial) > 0) and (json_reorder(
                initial) == json_reorder(subsequent))):
            return FILES_MATCH
        else:
            return FILES_DO_NOT_MATCH
    else:
        # os.path does not exist for one or both input files
        return INPUT_FILE_DOES_NOT_EXIST
###############################################################################
