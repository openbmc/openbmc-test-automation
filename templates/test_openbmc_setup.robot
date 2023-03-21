*** Settings ***
Documentation    Test suite to verify if the Robot setup is ready for use.

Resource         ../lib/resource.robot
Resource         ../lib/rest_client.robot
Resource         ../lib/connection_client.robot
Resource         ../lib/ipmi_client.robot
Resource        ../lib/bmc_redfish_resource.robot

*** Test Cases ***

Test Redfish Setup
    [Documentation]  Verify Redfish works.

    Skip If  ${REDFISH_SUPPORT_TRANS_STATE} == ${0}
    ...  Skipping Redfish check, user explicitly requested for REST.

    Redfish.Login
    Redfish.Get  /redfish/v1/
    Redfish.Logout


Test REST Setup
    [Documentation]  Verify REST works.

    Skip If  ${REDFISH_SUPPORT_TRANS_STATE} == ${1}
    ...  Skipping REST check, user explicitly requested for Redfish.

    # REST Connection and request.
    Initialize OpenBMC
    # Raw GET REST operation to verify session is established.
    ${resp}=  GET On Session  openbmc  /xyz/openbmc_project/  expected_status=any
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    Log To Console  \n ${resp.json()}


Test SSH Setup
    [Documentation]  Verify SSH works.

    ${stdout}  ${stderr}  ${rc}=  BMC Execute Command  uname -a  print_out=1  print_err=1
    IF  ${rc}
        Fail    BMC SSH login failed.
    END


Test IPMI Setup
    [Documentation]  Verify Out-of-band works.

    ${chassis_status}=  Run IPMI Standard Command  chassis status
    Log To Console  \n ${chassis_status}
