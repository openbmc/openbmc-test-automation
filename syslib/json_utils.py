#!/usr/bin/env python


r"""
This module contains json functions to supplement robot
"""

import json
    
    
# internal utility for json_utils - sort a json data structure
def j_reorder(obj):
    if isinstance(obj, dict):
        return sorted((k, j_reorder(v)) for k, v in obj.items())
    if isinstance(obj, list):
        return sorted(j_reorder(item) for item in obj)
    else:
        # pprint(obj)   print the final element value
        return obj



###############################################################################
def json_file_contents_identical (file1, file2):
    r"""
     Compare two json text files.   
     Json entries and their values are compared.  
     Comparison checking is independent of the order of entries in the two files. 
     Returns True if same, False otherwise.
    """

    with open(file1, 'r') as f:
        aa = json.load(f)
    f.close()
    with open(file2, 'r') as g:
        zz = json.load(g)
    g.close()


    if j_reorder(aa) == j_reorder(zz):
        return True
    else:
        return False
###############################################################################


