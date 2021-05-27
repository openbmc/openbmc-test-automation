*** Settings ***
Documentation    Test MPIPL.

Resource         ../../lib/resource.robot
Resource         ../../lib/openbmc_ffdc.robot
Resource         ../../lib/bmc_redfish_utils.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/boot_utils.robot

Test Teardown    Test Teardown Execution

*** Variables ***

${user_initated_mpipl}  systemctl start obmc-host-crash@0.target

** Test Cases **

Trigger And Verify User Initiated Dump Using Diagnostic Mode Target
    [Documentation]  Trigger And Verify user initiated dump using diagnostic mode target
    [Tags]  Trigger_And_Verify_User_Initiated_Dump_Using_Diagnostic_Mode_Target

    Redfish.Login

    # Power off
    Redfish Power Off

    # Power on
    Redfish Power On

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

Trigger And Verify User Initiated Dump Using Redfish
    [Documentation]  Verify redfish triggered MPIPL flow
    [Tags]  Trigger_And_Verify_User_Initiated_Dump_Using_Redfish

    Redfish.Login

    # Power off
    Redfish Power Off

    # Power on
    Redfish Power On

    # Trigger MPIPL
    ${payload} =  Create Dictionary
    ...  DiagnosticDataType=OEM  OEMDiagnosticDataType=System
    Redfish.Post  ${DUMP_URI}/Dump/Actions/LogService.CollectDiagnosticData  body=&{payload}
    ...  valid_status_codes=[${HTTP_ACCEPTED}]

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
    FFDC On Test Case Fail

