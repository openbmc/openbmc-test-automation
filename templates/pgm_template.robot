*** Settings ***

# Copy this template as a base to get a start on a robot program. You may
# remove any generic comments (like this one).

Documentation  Base to get a start on a robot program.

Library                     pgm_template.py
Library                     gen_print.py
Library                     gen_robot_print.py

Suite Setup                 Suite Setup
Suite Teardown              Suite Teardown
Test Setup                  Test Setup

*** Variables ***
# Initialize program parameters variables.
# Create parm_list containing all of our program parameters.
@{parm_list}                TEST_MODE  QUIET  DEBUG

# Initialize each program parameter.
${TEST_MODE}                0
${QUIET}                    0
${DEBUG}                    0


*** Test Cases ***
Test Case 1
    [Documentation]  <test case doc here>
    Print Timen  First test case.
