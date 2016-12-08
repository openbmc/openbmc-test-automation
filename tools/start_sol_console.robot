*** Settings ***
Documentation       Start SOL collection.

Library   ../lib/gen_print.py
Library   ../lib/gen_robot_print.py
Library   ../lib/gen_robot_valid.py

Resource  ../lib/utils.robot

*** Variables ***
@{parm_list}                test_mode  quiet  debug

# Initialize each program parameter.
${test_mode}                0
${quiet}                    0
${debug}                    0


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

    Rqprint Pgm Header

################################################################################



################################################################################
Program Teardown

    Rqprint Pgm Footer

################################################################################
