#!/usr/bin/env python

r"""
This module contains keyword functions to supplement robot's built in
functions and use in test where generic robot keywords don't support.
"""

try:
    from robot.libraries.BuiltIn import BuiltIn
    from robot.libraries import DateTime
except ImportError:
    pass
import time
import os
import difflib


##########################################################################
def JSON_Inv_File_Diff_Check(file1_path,
                             file2_path,
                             diff_file_path,
                             skip_dictionary):
    r"""
    Compare the contents of two files which contain inventory data in
    JSON format.  The comparison is similar to the unix 'diff' command but
    the output lists the hardware subsystem (category) where differences
    are found, and some differences are selectively ignored.  The items
    ignored are defined in the skip_dictionary dictionary.

    Description of arguments:
    file1_path       File containing JSON formatted data.
    file2_path       File to compare to file1 to.
    diff_file_path   File which will contain the resulting difference report.
    skip_dictionary  Dictionary which defines what inventory items
                     to ignore if there are differences in inventory
                     files -- some differences are expected or
                     immaterial.  Specify items in this dictionary
                     if there are inventory items that should be
                     ignored whenever a comparison between inventory
                     files is done.  For example, assigned processor
                     speed routinely varies depending upon the
                     needs of OCC/tmgt/ondemand governor.
                     Back-to-back inventory runs will show
                     processor speed differences even if nothing
                     else was run between them.
                     Each dictionary entry is of the form
                     category:leafname where category is a JSON
                     hardware category such as "processor", "memory",
                     "disk", "display", "network", etc.,
                     and leafname is a leaf node (atribute name)
                     within that category.
                     For example: {'processor':'size'}, or
                     {'processor':'size','memory':'claimed','display':'id'}.


    Sample difference report:
    Difference at line 102  (in section "memory":)
     102 -   "slot": "UOPWR.BAR.1315ACA-DIMM0",
     102 +   "slot": "0"
    Difference at line 126  (in section "processor":)
     126 -   "size": 2151000000,    +++ NOTE! This is an ignore item
     126 +   "size": 2201000000,    +++ NOTE! This is an ignore item

    Returns:
    0 if both files contain the same information or they differ only in
      items specified as those to ignore.
    2 if FILES_DO_NOT_MATCH.
    3 if INPUT_FILE_DOES_NOT_EXIST.
    4 if IO_EXCEPTION_READING_FILE.
    5 if IO_EXCEPTION_WRITING_FILE.
    """

    FILES_MATCH = 0
    FILES_DO_NOT_MATCH = 2
    INPUT_FILE_DOES_NOT_EXIST = 3
    IO_EXCEPTION_READING_FILE = 4
    IO_EXCEPTION_WRITING_FILE = 5

    # Hardware categories which are reported in the JSON inventory files.
    hardware_categories = ['\"processor\":', '\"memory\":', '\"disk\":',
                           '\"I/O\":', '\"display\":', '\"generic\":',
                           '\"network\":', '\"communication\":',
                           '\"printer\":', '\"input\":', '\"multimedia\":',
                           '\"tape\":']

    # The minimum size in bytes a JSON file must be.
    min_json_byte_size = 16

    now = time.strftime("At %Y-%m-%d %H:%M:%S")

    if (not os.path.exists(file1_path) or (not os.path.exists(file2_path))):
        return INPUT_FILE_DOES_NOT_EXIST
    try:
        with open(file1_path, 'r') as file:
            initial = file.readlines()
        with open(file2_path, 'r') as file:
            final = file.readlines()
    except IOError:
        file.close()
        return IO_EXCEPTION_READING_FILE
    except ValueError:
        file.close()
        return INPUT_FILE_MALFORMED
    else:
        file.close()

    # Must have more than a trivial number of bytes.
    if len(initial) <= min_json_byte_size:
        return INPUT_FILE_MALFORMED

    if (initial == final):
        try:
            file = open(diff_file_path, 'w')
            line_to_print = now + " found no difference between file " + \
                file1_path + " and " + \
                file2_path + "\n"
            file.write(line_to_print)
            file.close()
        except IOError:
            file.close()
        return FILES_MATCH

    # Find the differences and write difference report to diff_file_path file.
    try:
        file = open(diff_file_path, 'w')
        line_to_print = now + " compared files " + \
            file1_path + " and " + \
            file2_path + "\n"
        file.write(line_to_print)

        diff = difflib.ndiff(initial, final)
        # The diff array contains both lines that match
        # and lines that differ in the initial and final arrays.
        # The first two characters of each line
        # are prefixed with two letters, defined as:
        # '- ' This line is unique to initial
        # '+ ' This line is line unique to final
        # '  ' This line is common to both, and
        # '? ' This line indicates approximate differences.
        # For example,  comparing two three-line files:
        #  This line is in both initial and final.
        #  This line is too but the next line is different in each file.
        # -                     "size": 2101000000,
        # ?                              - ^
        # +                     "size": 2002000000,
        # ?                               ^^

        print_header_flag = False
        category = ""
        row_num = 1
        item_we_cannot_ignore = False

        for my_line in diff:
            diff_item = my_line.strip('\n')
            # If it's a Category, such as processor or memory,
            # save it.  We will print it out later.
            for hdw_cat in hardware_categories:
                if (hdw_cat in diff_item):
                    # If we don't have a match we will reuse
                    # the prvious category.
                    category = hdw_cat
            # Lines beginning with minus or plus or q-mark are
            # true difference items.
            # We want to look at those in more detail.
            if diff_item.startswith('? '):
                # we can ignore these
                continue
            elif (diff_item.startswith('- ') or diff_item.startswith('+ ')):
                # If we have not printed the header line for this
                # difference, print it now.
                if print_header_flag is False:
                    line_to_print = "Difference at line " + \
                     str(row_num) + "  (in section " + \
                     category + ")\n"
                    file.write(line_to_print)
                # If this is in the ignore dictionary, we'll print
                # it but also add text that it is an ignore item.
                skipitem = False
                for key, value in skip_dictionary.iteritems():
                    if ((key in category.lower().strip()) and
                       (value in diff_item.lower().strip())):
                        line_to_print = "  " + \
                            str(row_num) + " " + diff_item + \
                            "    +++ NOTE! This difference is in" + \
                            " the inventory ignore list and" + \
                            " can be ignored. +++\n"
                        # set flag indicating this item is a skip item
                        skipitem = True
                        break
                if skipitem is False:
                    # Its not a skip item, that is,
                    # this is not on the ignore list.
                    # Print the item and set the item_we_canot_ignore flag
                    # indicating we have an item not on the ignore list.  The
                    # flag will determine the return code we
                    # pass back to the user at the end.
                    item_we_cannot_ignore = True
                    line_to_print = "  " + \
                        str(row_num) + " " + diff_item + "\n"
                file.write(line_to_print)
                print_header_flag = True

            else:
                # Adjust row numbering as a difference is only one line
                # but it takes several lines in the diff file.
                if print_header_flag is True:
                    row_num = row_num + 1
                    print_header_flag = False
                row_num = row_num + 1

        # Make sure we end the file.
        file.write("\n")
        file.close()

    except IOError:
        file.close()
        return IO_EXCEPTION_WRITING_FILE

    if item_we_cannot_ignore:
        # We have at least one diff_item not on the ignore list.
        return FILES_DO_NOT_MATCH
    else:
        # Any differences were on the ignore list.
        return FILES_MATCH
###############################################################################


###############################################################################


def run_until_keyword_fails(retry,
                            retry_interval,
                            name,
                            *args):
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
