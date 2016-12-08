*** Settings ***
Documentation       Stop SOL collection and write to FFDC.

Library   ../lib/gen_print.py
Library   ../lib/gen_robot_print.py
Library   ../lib/gen_robot_valid.py
Resource  ../lib/openbmc_ffdc_methods.robot
Resource  ../lib/openbmc_ffdc_utils.robot
Resource  ../lib/utils.robot

*** Variables ***
@{parm_list}                ffdc_file_prefix  ffdc_dir_path  test_mode  quiet  debug

# Initialize each program parameter.
${ffdc_file_prefix}         ${EMPTY}
${ffdc_dir_path}            ${EMPTY}
${test_mode}                0
${quiet}                    0
${debug}                    0

*** Test Cases ***
Stop Sol Console
    [Teardown]  Program Teardown
    [Documentation]  Stop SOL Console Logging and write SOL to file.
    ...              By Default write to logs/testSuite/testName/date_SOL.text

    Setup
    Rprint Timen  Stopping SOL Console Logging.
    ${sol_log}=  Stop SOL Console Logging
    ${logpath}=  Catenate  SEPARATOR=  ${ffdc_dir_path}${ffdc_file_prefix}_  SOL.txt
    Write Data to File  ${sol_log}  ${logpath}
    Rprintn
    rpvars  logpath
    Rprint Timen  Stopped SOL Console Logging.


*** Keywords ***
################################################################################
Setup

    Rprintn

    Validate Parms

    Rqprint Pgm Header

################################################################################


################################################################################
Validate Parms

    ${cur_time}=  Get Current Time Stamp
    Run Keyword If  '${ffdc_file_prefix}' == '${EMPTY}'  Set Global Variable
    ...  ${ffdc_file_prefix}  ${cur_time}

    Run Keyword If  '${ffdc_dir_path}' == '${EMPTY}'   Set Global Variable
    ...  ${ffdc_dir_path}  ${FFDC_LOG_PATH}${suitename}${/}${testname}${/}

    Rvalid Value  ffdc_file_prefix
    Rvalid Value  ffdc_dir_path

    return from keyword

################################################################################



################################################################################
Program Teardown


    Rqprint Pgm Footer

################################################################################
