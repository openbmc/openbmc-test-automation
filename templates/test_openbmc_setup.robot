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

    Redfish.Login
    Redfish.Get  /redfish/v1/
    Redfish.Logout


Test REST Setup
    [Documentation]  Verify REST works.

    # REST Connection and request.
    Initialize OpenBMC
    # Raw GET REST operation to verify session is established.
    ${resp}=  Get Request  openbmc  /xyz/openbmc_project/
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    ${content}=  To JSON  ${resp.content}  pretty_print=True
    Log To Console  \n ${content}


Test SSH Setup
    [Documentation]  Verify SSH works.

    BMC Execute Command  uname -a


Test IPMI Setup
    [Documentation]  Verify Out-of-band works.

    ${chassis_status}=  Run IPMI Standard Command  chassis status
    Log To Console  \n ${chassis_status}
