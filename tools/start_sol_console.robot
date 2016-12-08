*** Settings ***
Documentation  Start SOL collection.

Library   ../lib/gen_robot_print.py
Library   ../lib/gen_robot_valid.py

Resource  ../lib/utils.robot

*** Variables ***
@{parm_list}                openbmc_password  openbmc_host  openbmc_username
...  debug  test_mode  quiet

# Initialize each program parameter.
${test_mode}                0
${quiet}                    0
${debug}                    0
${openbmc_host}             ${EMPTY}
${openbmc_username}         root
${openbmc_password}         0penBmc

*** Test Cases ***
Start Sol Console
    [Teardown]  Program Teardown
    [Documentation]  Start SOL Console Logging.

    Setup
    Rprint Timen  Starting SOL Console Logging.
    Start SOL Console Logging
    Rprint Timen  Started SOL Console Logging.


*** Keywords ***
################################################################################
Setup

    Rprintn

    Validate Parms

    Rqprint Pgm Header

################################################################################


################################################################################
Validate Parms

    Rvalid Value  openbmc_host
    Rvalid Value  openbmc_username
    Rvalid Value  openbmc_password

################################################################################


################################################################################
Program Teardown

    Rqprint Pgm Footer

################################################################################
