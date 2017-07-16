#!/usr/bin/env python

r"""
This module contains keyword functions to supplement robot's built in
functions and use in test where generic robot keywords don't support.

"""
import time
try:
    from robot.libraries.BuiltIn import BuiltIn
    from robot.libraries import DateTime
except ImportError:
    pass
import re
import os
import fileinput
import difflib
import datetime as dt
from utils_variables import *

##########################################################################
def skip_inventory_item(category, item):
    r"""
    Utility routeint that returns True if the category and item are
    found in the I_FILE_SKIP_DICT ignore dictionary, returns
    False otherwise.

    Description of argument(s):
    category   Cetegory name of an item to skip, for example processor
    item       Leaf node under the item, for example  size
    """
    low_cat = (category.lower()).strip()
    low_item = (item.lower()).strip()
    for k, v in I_FILE_SKIP_DICT.iteritems():
        if (k in low_cat) and (v in low_item):
            return True
    return False
##########################################################################

##########################################################################
def json_inv_file_diff_check(initial_inv_file, final_inv_file, diff_file):
    r"""
     Compares the contents of two JSON files which contain inventory data.

     Description of argument(s):
     initial_inv_file   Name and path of file containing JSON formated data.
     final_inv_file     Name and path of file to compare to the initial file.
     diff_file          Name and path of file where differences are
                         written to.

     Returns
     0 if both files contain the same information.
     2 if FILES_DO_NOT_MATCH. The differences will be written to diff_file.
     3 if INPUT_FILE_DOES_NOT_EXIST.
     4 if IO_EXCEPTION_READING_FILE.
     5 IO_EXCEPTION_WRITING_FILE.
    """
    # the minimum size in bytes a JSON file must be
    min_json_byte_size = 16

    now = time.strftime("At %Y-%m-%d %H:%M:%S")

    if (os.path.exists(initial_inv_file)
            and os.path.exists(final_inv_file)):
        f = open(initial_inv_file, 'r')
        try:
            initial = f.readlines()
        except IOError:
            f.close()
            return I_IO_EXCEPTION_READING_FILE
        except ValueError:
            f.close()
            return I_INPUT_FILE_MALFORMED
        else:
            f.close()

        f = open(final_inv_file, 'r')
        try:
            final = f.readlines()
        except IOError:
            f.close()
            return I_IO_EXCEPTION_READING_FILE
        except ValueError:
            f.close()
            return I_INPUT_FILE_MALFORMED
        else:
            f.close()

        # must have more than a trivial number of bytes and must compare
        if ((len(initial) > min_json_byte_size) and (initial == final)):
            try:
                f = open(diff_file, 'w')
                linetoprint = now + " found no difference between file " + \
                    initial_inv_file + " and " + final_inv_file + "\n"
                f.write(linetoprint)
                f.close()
            except IOError:
                f.close()
            else:
                pass
            return I_FILES_MATCH
        else:

            # find the differences and write them to the diff_file file

            try:
                f = open(diff_file, 'w')
                linetoprint = now + " compared files " + \
                    initial_inv_file + " and " + final_inv_file + "\n"
                f.write(linetoprint)

                diff = difflib.ndiff(initial, final)

                print_header_flag = 0
                category = ""
                the_row = 1
                item_we_cannot_ignore = False

                for myline in diff:
                    # get the line
                    diffitem = myline.strip('\n')
                    # if its a category, such as *processor or *memory, save it--we'll
                    # print it out later
                    for hh in I_CATS:
                        if (hh in diffitem):
                            category = hh
                            #print "Processing category ",category
                    # lines beginning with minus or plus or q-mark are
                    # true difference items.
                    # we want to look at those in more detail
                    if ((diffitem.startswith('- ')) or (diffitem.startswith('+ '))
                            or (diffitem.startswith('? '))):
                        if ((diffitem.startswith('- '))
                                or (diffitem.startswith('+ '))):
                            # if we have not printed the header line for this
                            # difference, print it now
                            if (print_header_flag == 0):
                                linetoprint = "Difference at line " + \
                                    str(the_row) + "  (in section " + category + ")\n"
                                f.write(linetoprint)
                            # if this is in the ignore dictionary, we'll print
                            # it but also list it as an ignore item
                            if skip_inventory_item(category, diffitem):
                                linetoprint = "  " + \
                                    str(the_row) + " " + diffitem + \
                                    "    +++ NOTE! This difference is in the" + \
                                    " inventory ignore list and" + \
                                    " can be ignored. +++\n"
                            else:
                                # this is an item not on the ignore list.  print the
                                # item and set the flag that we
                                # have an item not on the ignore list.  The flag will
                                # determine the # return code we pass back to the
                                # user at the end
                                item_we_cannot_ignore = True
                                linetoprint = "  " + \
                                    str(the_row) + " " + diffitem + "\n"
                            f.write(linetoprint)
                            print_header_flag = 1
                        else:
                            continue
                    else:
                        # adjust row numbering as a difference is only one line but it
                        # takes up several lines in the diff file
                        if (print_header_flag == 1):
                            the_row = the_row + 1
                            print_header_flag = 0
                        the_row = the_row + 1

                f.write("\n")   # make sure we end the file
                f.close()

            except IOError:
                f.close()
                return I_IO_EXCEPTION_WRITING_FILE

            else:
                if item_we_cannot_ignore:
                    # we have at least one diffitem not on the ignore list
                    return I_FILES_DO_NOT_MATCH
                else:
                    # any differences were on the ignore list
                    return I_FILES_MATCH

    else:
        # os.path does not exist for one or both input files
        return I_INPUT_FILE_DOES_NOT_EXIST
###############################################################################

###############################################################################


def run_until_keyword_fails(retry, retry_interval, name, *args):
    r"""
    Execute a robot keyword repeatedly until it either fails or the timeout
    value is exceeded.
    Note: Opposite of robot keyword "Wait Until Keyword Succeeds".

    Description of argument(s):
    retry              Max timeout time in hour(s).
    retry_interval     Time interval in minute(s) for looping.
    name               Robot keyword to execute.
    args               Robot keyword arguments.
    """

    # Convert the retry time in seconds
    retry_seconds = DateTime.convert_time(retry)
    timeout = time.time() + int(retry_seconds)

    # Convert the interval time in seconds
    interval_seconds = DateTime.convert_time(retry_interval)
    interval = int(interval_seconds)

    BuiltIn().log(timeout)
    BuiltIn().log(interval)

    while True:
        status = BuiltIn().run_keyword_and_return_status(name, *args)

        # Return if keywords returns as failure.
        if status is False:
            BuiltIn().log("Failed as expected")
            return False
        # Return if retry timeout as success.
        elif time.time() > timeout > 0:
            BuiltIn().log("Max retry timeout")
            return True
        time.sleep(interval)
        BuiltIn().log(time.time())

    return True
###############################################################################


###############################################################################
def htx_error_log_to_list(htx_error_log_output):

    r"""
    Parse htx error log output string and return list of strings in the form
    "<field name>:<field value>".
    The output of this function may be passed to the build_error_dict function.

    Description of argument(s):
    htx_error_log_output        Error entry string containing the stdout
                                generated by "htxcmdline -geterrlog".

    Example of htx_error_log_output contents:

    ######################## Result Starts Here ###############################
    Currently running ECG/MDT : /usr/lpp/htx/mdt/mdt.whit
    ===========================
    ---------------------------------------------------------------------
    Device id:/dev/nvidia0
    Timestamp:Mar 29 19:41:54 2017
    err=00000027
    sev=1
    Exerciser Name:hxenvidia
    Serial No:Not Available
    Part No:Not Available
    Location:Not Available
    FRU Number:Not Available
    Device:Not Available
    Error Text:cudaEventSynchronize for stopEvent returned err = 0039 from file
               , line 430.
    ---------------------------------------------------------------------
    ---------------------------------------------------------------------
    Device id:/dev/nvidia0
    Timestamp:Mar 29 19:41:54 2017
    err=00000027
    sev=1
    Exerciser Name:hxenvidia
    Serial No:Not Available
    Part No:Not Available
    Location:Not Available
    FRU Number:Not Available
    Device:Not Available
    Error Text:Hardware Exerciser stopped on error
    ---------------------------------------------------------------------
    ######################### Result Ends Here ################################

    Example output:
    Returns the lists of error string per entry
    ['Device id:/dev/nvidia0',
     'Timestamp:Mar 29 19:41:54 2017',
     'err=00000027',
     'sev=1',
     'Exerciser Name:hxenvidia',
     'Serial No:Not Available',
     'Part No:Not Available',
     'Location:Not Available',
     'FRU Number:Not Available',
     'Device:Not Available',
     'Error Text:cudaEventSynchronize for stopEvent returned err = 0039
                 from file , line 430.']
    """

    # List which will hold all the list of entries.
    error_list = []

    temp_error_list = []
    parse_walk = False

    for line in htx_error_log_output.splitlines():
        # Skip lines starting with "#"
        if line.startswith("#"):
            continue

        # Mark line starting with "-" and set parse flag.
        if line.startswith("-") and parse_walk is False:
            parse_walk = True
            continue
        # Mark line starting with "-" and reset parse flag.
        # Set temp error list to EMPTY.
        elif line.startswith("-"):
            error_list.append(temp_error_list)
            parse_walk = False
            temp_error_list = []
        # Add entry to list if line is not emtpy
        elif parse_walk:
            temp_error_list.append(str(line))

    return error_list
###############################################################################


###############################################################################
def build_error_dict(htx_error_log_output):

    r"""
    Builds error list into a list of dictionary entries.

    Description of argument(s):
    error_list        Error list entries.

    Example output dictionary:
    {
      0:
        {
          'sev': '1',
          'err': '00000027',
          'Timestamp': 'Mar 29 19:41:54 2017',
          'Part No': 'Not Available',
          'Serial No': 'Not Available',
          'Device': 'Not Available',
          'FRU Number': 'Not Available',
          'Location': 'Not Available',
          'Device id': '/dev/nvidia0',
          'Error Text': 'cudaEventSynchronize for stopEvent returned err = 0039
                         from file , line 430.',
          'Exerciser Name': 'hxenvidia'
        },
      1:
        {
          'sev': '1',
          'err': '00000027',
          'Timestamp': 'Mar 29 19:41:54 2017',
          'Part No': 'Not Available',
          'Serial No': 'Not Available',
          'Device': 'Not Available',
          'FRU Number': 'Not Available',
          'Location': 'Not Available',
          'Device id': '/dev/nvidia0',
          'Error Text': 'Hardware Exerciser stopped on error',
          'Exerciser Name': 'hxenvidia'
        }
    },

    """

    # List which will hold all the list of entries.
    error_list = []
    error_list = htx_error_log_to_list(htx_error_log_output)

    # dictionary which holds the error dictionry entry.
    error_dict = {}

    temp_error_dict = {}
    error_index = 0

    # Loop through the error list.
    for entry_list in error_list:
        # Loop through the first error list entry.
        for entry in entry_list:
            # Split string into list for key value update.
            # Example: 'Device id:/dev/nvidia0'
            # Example: 'err=00000027'
            parm_split = re.split("[:=]", entry)
            # Populate temp dictionary with key value pair data.
            temp_error_dict[str(parm_split[0])] = parm_split[1]

        # Update the master dictionary per entry index.
        error_dict[error_index] = temp_error_dict
        # Reset temp dict to EMPTY and increment index count.
        temp_error_dict = {}
        error_index += 1

    return error_dict

###############################################################################
