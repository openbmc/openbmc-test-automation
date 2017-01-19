*** Settings ***
Documentation  Run the caller's keyword string.

# NOTE: Robot searches PYTHONPATH for libraries.
Library   run_keyword.py


*** Variables ***
# Initialize program parameters variables.
# Create parm_list containing all of our program parameters.  parm_list is
# used by "rqprint_pgm_header".
@{parm_list}                keyword_string  lib_file_path  test_mode  quiet
...  debug

# Initialize each program parameter.
${keyword_string}           ${EMPTY}
${lib_file_path}            ${EMPTY}
${test_mode}                0
${quiet}                    0
${debug}                    0


*** Test Cases ***
Run Keyword Pgm
    Main

*** Keywords ***
###############################################################################
Main
    [Teardown]  Program Teardown

    Main Py

###############################################################################

