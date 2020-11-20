*** Settings ***
Documentation    Test MPIPL.

Resource         ../gui/lib/resource.robot
Resource         ../lib/openbmc_ffdc.robot
Resource         ../lib/bmc_redfish_utils.robot
Resource         ../lib/bmc_redfish_resource.robot
Resource         ../lib/resource.robot 

Test Setup        
Test Teardown    Test Teardown Execution

*** Variables ***

${user_initated_mpipl}   systemctl start obmc-host-diagnostic-mode@0.target

** Test Cases **

Verify User initiated MPIPL
    [Documentation]  Verify user initiated MPIPL flow
    [Tags]  Verify_USER_INITIATED_MPIPL

    Redfish.Login

    # Power off
    Redfish.Post  ${REDFISH_POWER_URI}
    ...  body={'ResetType': 'ForceOff'}   valid_status_codes=[200]

    Sleep  120

    # Confirm power off
    ${res}  ${stderr}  ${rc} =  BMC Execute Command  obmcutil state  
    Should Contain  ${res}  PowerState.Off  

    # Power on
    Redfish.Post  ${REDFISH_POWER_URI}
    ...  body={'ResetType': 'On'}   valid_status_codes=[200]

    Sleep  240 

    # Confirm power on
    ${res}  ${stderr}  ${rc} =  BMC Execute Command  obmcutil state
    Should Contain  ${res}  OSStatus.Standby 

    # Trigger MPIPL
    BMC Execute Command  ${user_initated_mpipl}
    Sleep  240

    # Confirm boot after MPIPL
    ${res}  ${stderr}  ${rc} =  BMC Execute Command  obmcutil state
    Should Contain  ${res}  OSStatus.Standby   

    ${p0_cfam}  ${stderr}  ${rc} =  BMC Execute Command  pdbg -p0 getcfam 0x2809 
    Should Contain  ${p0_cfam}  0x854 
    Printn  ${p0_cfam}

    ${p1_cfam}  ${stderr}  ${rc} =  BMC Execute Command  pdbg -p1 getcfam 0x2809 
    Should Contain  ${p1_cfam}  0x854
    Printn  ${p1_cfam}

Verify Redfish Initiated MPIPL
    [Documentation]  Verify redfish triggered MPIPL flow
    [Tags]  Verify_REDFISH_INITIATED_MPIPL

    Redfish.Login

    # Power off
    Redfish.Post  ${REDFISH_POWER_URI}
    ...  body={'ResetType': 'ForceOff'}   valid_status_codes=[200]

    Sleep  120

    # Confirm power off
    ${res}  ${stderr}  ${rc} =  BMC Execute Command  obmcutil state
    Should Contain  ${res}  PowerState.Off

    # Power on
    Redfish.Post  ${REDFISH_POWER_URI}
    ...  body={'ResetType': 'On'}   valid_status_codes=[200]

    Sleep  180

    # Confirm power on
    ${res}  ${stderr}  ${rc} =  BMC Execute Command  obmcutil state
    Should Contain  ${res}  OSStatus.Standby

    # Trigger MPIPL
    ${payload} =  Create Dictionary
    ...  DiagnosticDataType=OEM  OEMDiagnosticDataType=System
    Redfish.Post  /redfish/v1/Systems/system/LogServices/Dump/Actions/LogService.CollectDiagnosticData  body=&{payload}
    ...  valid_status_codes=[${HTTP_ACCEPTED}]

    Sleep  180
    ${res}  ${stderr}  ${rc} =  BMC Execute Command  obmcutil state
    Should Contain  ${res}  OSStatus.Standby
    ${p0_cfam}  ${stderr}  ${rc} =  BMC Execute Command  pdbg -p0 getcfam 0x2809
    Should Contain  ${p0_cfam}  0x854
    Printn  ${p0_cfam}

    ${p1_cfam}  ${stderr}  ${rc} =  BMC Execute Command  pdbg -p1 getcfam 0x2809
    Should Contain  ${p1_cfam}  0x854
    Printn  ${p1_cfam}


*** Keywords ***

Test Teardown Execution
    [Documentation]  Do the post test teardown.

    Run Keyword And Ignore Error  Redfish.Logout
    #FFDC On Test Case Fail 

