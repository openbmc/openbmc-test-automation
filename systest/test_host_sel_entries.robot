*** Settings ***
Documentation    Test SEL records are being posted and SEL parsing tool works
...              correctly.

Library          ../gui/obmc_asmi/lib/supporting_libs.py
Library          OperatingSystem
Resource         ../lib/resource.txt
Resource         ../lib/openbmc_ffdc_methods.robot
Resource         ../syslib/utils_os.robot
Resource         ../lib/rest_client.robot
Variables        ../data/variables.py

Suite Teardown  Close All Connections

*** Variables ***
${WSP_OP_TOOLS_PATH}   ${EMPTY}
${FW_VERSION}          ${EMPTY}

*** Test Cases ***
OP BMC SEL Entries
    [Documentation]  Test BMC sel entries correctly decoded
    # This Tc needs from eSEL.pl binaries saved as an environment variable
    Initialize OpenBMC
    Log  Getting esel data
    ${SYSNAME} =  Get System Name  ${OPENBMC_HOST}
    ${SYSNAME} =  Set Variable  ${SYSNAME}_${FW_VERSION}_
    Collect eSEL Log  ${SYSNAME}

    Log  Verify decoded file exists
    ${resp}  ${value}  Run Keyword And Ignore Error
    ...  OperatingSystem.File Should Exist  ${SYSNAME}esel.txt
    Run Keyword if  '${resp}'=='FAIL'
    ...  Fail  Failed esel.out.txt creation, output:\n${value}

    Log  Verifying esel.out file was decoded correctly.
    # Validate esel.txt format is correct
    Verify Format  .*Platform Event Log - .*x.*  ${SYSNAME}
    Verify Format  .*Private Header.*  ${SYSNAME}
    Verify Format  .*User Header.*  ${SYSNAME}
    Verify Format  .*Primary System Reference Code.*  ${SYSNAME}
    Verify Format  .*User Defined Data.*  ${SYSNAME}

*** Keywords ***
Verify Format
    [Documentation]  Verify esel format.
    [Arguments]  ${REGEXP}  ${SYSNAME}
    ${output} =  Run  cat ${SYSNAME}esel.txt
    ${matches} =  Get Regexp Matches  ${output}  ${REGEXP}
    ${len} =  Get Length  ${matches}
    Run Keyword If  ${len} < 1
    ...  Fail  Error: esel decoded incorrectly, check esel.out.txt for details

Get System Name
    [Documentation]  Get system name.
    [Arguments]  ${OS_IP_HOSTNAME}
    ${hostname} =  Get Hostname From Ip Address  ${OS_IP_HOSTNAME}
    ${hostname} =  Split String  ${hostname}  .
    [Return]  ${hostname[0]}