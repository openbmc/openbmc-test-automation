*** Settings ***
Documentation    Test suite to verify if the robot setup is ready for use.

Resource         ../lib/resource.txt
Resource         ../lib/rest_client.robot
Resource         ../lib/connection_client.robot
Resource         ../lib/ipmi_client.robot

*** Test Cases ***

Test OpenBmc Automation Setup
    [Documentation]  Verify REST, SSH, Out-of-band IPMI and others.

    Log To Console  \n *** Testing REST Setup ***

    # REST Connection and request.
    Initialize OpenBMC
    # Raw GET REST operation to verify session is established.
    ${resp}=  Get Request  openbmc  /xyz/openbmc_project/
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    ${content}=  To JSON  ${resp.content}  pretty_print=True
    Log To Console  \n ${content}

    Log To Console  \n *** Testing SSH Setup ***

    # SSH Connection and request.
    Open Connection And Log In
    ${bmc_kernel}=  Execute Command  uname -a
    Log To Console  \n ${bmc_kernel}

    Log To Console  \n *** Testing Out-of-band IPMI tool Setup ***

    # IPMI Connection and request.
    ${chassis_status}=  Run IPMI Standard Command  chassis status
    Log To Console  \n ${chassis_status}
