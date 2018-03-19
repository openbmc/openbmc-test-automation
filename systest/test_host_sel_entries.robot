*** Settings ***
Documentation    Test that SEL records are being posted and SEL parsing tool
...    works correctly

Library          ../gui/obmc_asmi/lib/supporting_libs.py
Library          OperatingSystem
Library          ../lib/gen_misc.py
Library          ../lib/gen_cmd.py
Resource         ../lib/resource.txt
Resource         ../lib/openbmc_ffdc_methods.robot
Resource         ../syslib/utils_os.robot
Resource         ../lib/rest_client.robot
Variables        ../data/variables.py

Suite Setup  Suite Setup Execution
Suite Teardown  Close All Connections

*** Variables ***
${FIRMWARE_VERSION}          ${EMPTY}

*** Test Cases ***
OP BMC SEL Entries
    [Documentation]  Test BMC sel entries correctly decoded
    # This Tc needs from eSEL.pl binaries saved as an environment variable
    Initialize OpenBMC
    Print Timen  Getting esel data
    ${OPENBMC_HOST_NAME}  ${OPENBMC_IP}  ${OPENBMC_HOST_SHORT_NAME}=
    ...  get_host_name_ip  ${OPENBMC_HOST}  ${1}
    ${log_prefix_path}=  Set Variable  ${OPENBMC_HOST_SHORT_NAME}_${FIRMWARE_VERSION}_
    ${ffdc_file_list}=  Collect eSEL Log  ${log_prefix_path}

    Print Timen  Verify decoded file exists
    ${resp}  ${value}  Run Keyword And Ignore Error
    ...  OperatingSystem.File Should Exist  ${SYSNAME}esel.txt
    Run Keyword if  '${resp}'=='FAIL'
    ...  Fail  Failed esel.out.txt creation, output:\n${value}

    Print Timen  Verifying esel.out file was decoded correctly.
    Verify Esel File Format  @{ffdc_file_list[1]}

*** Keywords ***
Verify Esel File Format
    [Documentation]  Verify esel format.
    [Arguments]  ${esel_file_path}
    # Description of argument(s):
    # esel_file_path  The path to the esel.txt file.
    @{regexes}=  Create List
    ...  .*Platform Event Log - .*x.*
    ...  .*Private Header.*
    ...  .*User Header.*
    ...  .*Primary System Reference Code.*
    ...  .*User Defined Data.*
    Qprint Timen  Verifying that ${esel_file_path} is a valid esel text file.
    :FOR  ${regex}  IN  @{regexes}
    \  ${cmd_buf}=  Catenate  grep -Eq '${regex}'  ${esel_file_path}
    \  cmd_fnc_u  ${cmd_buf}  ignore_err=${0}

Suite Setup Execution
    [Documentation]  Does setup tasks for the test case.

    Should Not Be Empty  ${FIRMWARE_VERSION}