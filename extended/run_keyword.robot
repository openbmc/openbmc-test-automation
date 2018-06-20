*** Settings ***
Documentation  Run the caller's keyword string.

# Description of parameters:
# keyword_string  The keyword string to be run by this program.  If this
#                 keyword string contains " ; " anywhere, it will be taken to
#                 be multiple keyword strings (see example below).  Each
#                 keywrod may also include a variable assignment.  Example:
#                 ${my_var}=  My Keyword
# lib_file_path   The path to a library or resource needed to run the keywords.
#                 This may contain a colon-delimited list of library/resource
#                 paths.
# test_mode       This means that this program should go through all the
#                 motions but not actually do anything substantial.
# debug           If this parameter is set to "1", this program will print
#                 additional debug information.
# quiet           If this parameter is set to "1", this program will print
#                 only essential information, i.e. it will not echo parameters,
#                 echo commands, print the total run time, etc.

# Example calls:
# cd $HOME/git/openbmc-test-automation
# export PYTHONPATH=${HOME}/git/openbmc-test-automation/lib/

# robot --outputdir=/tmp -v OPENBMC_HOST:barp01 -v 'keyword_string:Log To Console Hi.'
# extended/run_keyword.robot

# robot --outputdir=/tmp -v OPENBMC_HOST:barp01
# -v 'keyword_string:${state}= Get State quiet=${1} ; Rpvar state'
# -v lib_file_path:state.py extended/run_keyword.robot

# NOTE: Robot searches PYTHONPATH for libraries.
Library   run_keyword.py

Force Tags  Run_Keyword_Pgm

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
    [Documentation]  Run the keyword program.
    Main

*** Keywords ***
Main
    [Documentation]  Do main program processing.
    [Teardown]  Program Teardown

    Main Py
