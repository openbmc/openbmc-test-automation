*** Settings ***
Documentation    Test suite to verify if the Robot setup is ready for use.

Resource         ../lib/resource.robot
Resource         ../lib/connection_client.robot
Resource         ../lib/ipmi_client.robot
Resource         ../lib/bmc_redfish_resource.robot

Test Tags      Openbmc_Setup

*** Variables  ***

${REDFISH_SUPPORT_TRANS_STATE}   ${1}

*** Test Cases ***

Test Redfish Setup
    [Documentation]  Verify Redfish works.
    [Tags]  Test_Redfish_Setup

    Redfish.Login
    Redfish.Get  /redfish/v1/
    Redfish.Logout


Test SSH Setup
    [Documentation]  Verify SSH works.
    [Tags]  Test_SSH_Setup

    ${stdout}  ${stderr}  ${rc}=  BMC Execute Command  uname -a  print_out=1  print_err=1
    IF  ${rc}
        Fail    BMC SSH login failed.
    END


Test IPMI Setup
    [Documentation]  Verify Out-of-band works.
    [Tags]  Test_IPMI_Setup

    ${chassis_status}=  Run IPMI Standard Command  chassis status
    Log To Console  \n ${chassis_status}
