*** Settings ***

# Copy this template as a base to get a start on a robot program.
#
# Note: This is a template base code structure and not meant to
# work as it is directly without modification.

Documentation  Base to get a start on a robot program.

Library                     pgm_template.py
Library                     gen_print.py
Library                     gen_robot_print.py
Library                     gen_robot_valid.py
Resource                    bmc_redfish_resource.robot

# Write your own keyword(s) for setup and teardown
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
    [Documentation]  Test case 1 documentation.
    [Tags]  Test_Case_1

    Log To Console  First test case.
