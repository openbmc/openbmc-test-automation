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
import subprocess


##########################################################################
def json_inv_file_diff_check(file1_path,
                             file2_path,
                             diff_file_path,
                             skip_string):
    r"""
    Compare the contents of two files which contain inventory data in
    JSON format.  The comparison is similar to the unix 'diff' command but
    the output lists the hardware subsystem (category) where differences
    are found, and some differences are selectively ignored.  The items
    ignored are defined by the skip_string.

    Description of arguments:
    file1_path       File containing JSON formatted data.
    file2_path       File to compare to file1 to.
    diff_file_path   File which will contain the resulting difference report.
    skip_string      Comma delimited list of words which specify what shold be
                     ignored if there are inventory differences.  For example,
                     "size,speed".  Any line containing the word size or the
                     word speed will be ignored.
                     Processor speed (reported as "size" in JSON inventory
                     files) routinely varies depending upon the needs of the
                     tmgt/ondemand governor.  Back-to-back inventory runs may
                     show processor speed differences, which can optionally be
                     ignored.

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
        except IOError:
            file.close()
        line_to_print = "Specified skip (ignore) string = " + \
            skip_string + "\n\n"
        file.write(line_to_print)
        line_to_print = now + " found no difference between file " + \
            file1_path + " and " + \
            file2_path + "\n"
        file.write(line_to_print)
        file.close()
        return FILES_MATCH

    # Files are different.  Find the differences and write a difference report
    # to the diff_file_path file.
    try:
        file = open(diff_file_path, 'w')
    except IOError:
        file.close()
        return IO_EXCEPTION_WRITING_FILE

    line_to_print = "Specified skip (ignore) string = " + skip_string + "\n\n"
    file.write(line_to_print)
    line_to_print = now + " compared files " + \
        file1_path + " and " + \
        file2_path + "\n"
    file.write(line_to_print)

    # Form a UNIX diff command and its parameters as a list.  For example,
    # if skip_string="size,capacity",  command = ['diff', '-I "size"',
    # '-I "capacity"', 'file1_path', 'file2_path']
    command = ["diff"]
    # Split skip_string and add the itema as -I parameters to the command.
    if (skip_string != ""):
        ignore_items = skip_string.split(',')
        for item in ignore_items:
            item_parameter = ["-I \"" + item.strip() + "\""]
            command = command + item_parameter
    # Add the files to be diffed to the end of the command.
    command = command + [file1_path] + [file2_path]

    # Run the command and get the differences to stdout.
    p = subprocess.Popen(command, stdout=subprocess.PIPE)
    # get stdout
    out = p.communicate()[0]
    # Get the rc from diff.  rc=1 differences, rc=0 no difference.
    rc = p.returncode

    # Write the differences, if any, to the diff_file_path file.
    file.write(out)
    file.close()

    if rc == 0:
        # Any differences are on the ignore list.
        return FILES_MATCH
    else:
        # We have at least one diff_item not on the ignore list.
        return FILES_DO_NOT_MATCH
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
