*** Settings ***
Documentation  Stop SOL Console Logging and write SOL to a file.

Library   ../lib/gen_robot_print.py
Library   ../lib/gen_robot_valid.py
Resource  ../lib/openbmc_ffdc_methods.robot
Resource  ../lib/openbmc_ffdc_utils.robot
Resource  ../lib/utils.robot

*** Variables ***

@{parm_list}                ffdc_file_prefix  ffdc_dir_path  openbmc_host
...    openbmc_username  openbmc_password  debug  test_mode  quiet

# Initialize each program parameter.
${openbmc_host}             ${EMPTY}
${openbmc_username}         root
${openbmc_password}         0penBmc
${ffdc_file_prefix}         ${EMPTY}
${ffdc_dir_path}            ${EMPTY}
${test_mode}                0
${quiet}                    0
${debug}                    0
# We use the default ${file_path} in Stop SOL Console Logging.

*** Test Cases ***
Stop Sol Console
    [Teardown]  Program Teardown
    [Documentation]  Stop SOL Console Logging and write SOL to a file.

    Setup
    Rprint Timen  Stopping SOL Console Logging.
    ${sol_log}=  Stop SOL Console Logging

    ${logpath}=  Catenate  SEPARATOR=
    ...  ${ffdc_dir_path}${ffdc_file_prefix}_  SOL.txt
    Write Data to File  ${sol_log}  ${logpath}
    Rprintn
    Rpvars  logpath
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
    Rvalid Value  openbmc_host
    Rvalid Value  openbmc_username
    Rvalid Value  openbmc_password

################################################################################


################################################################################
Program Teardown

    Rqprint Pgm Footer

################################################################################
