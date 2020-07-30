*** Settings ***

Documentation     Test kyc feature on BMC.

Resource          ../../lib/rest_client.robot
Resource          ../../lib/openbmc_ffdc.robot
Resource          ../../lib/resource.robot
Resource          ../../lib/bmc_redfish_utils.robot
Resource          ../../lib/utils.robot
Resource          ../../lib/boot_utils.robot
Library           ../../lib/code_update_utils.py
Library           ../../lib/gen_robot_valid.py

Suite Setup       Suite Setup Execution
Test Teardown     Test Teardown Execution
Suite Teardown    Suite Teardown Execution


*** Test Cases ***

Redfish Session With ClientID
   [Documentation]  Create a session with ClientID.
   [Tags]  Redfish_Session_With_ClientID
   [Template]  Create Redfish Session With ClientID

   #ClientID
   12345
   123456


*** Keywords ***

Create Redfish Session With ClientID
    [Documentation]  Create redifish session with client id.
    [Arguments]  ${client_id}

    ${resp}=  Redfish Login  kwargs= "Oem":{"OpenBMC" : {"ClientID":"${client_id}"}}
    Set Test Variable  ${session_id}  ${resp['Id']}
    Verify Redfish Session Created With ClientID  ${client_id}  ${session_id}


Verify Redfish Session Created With ClientID
    [Documentation]  verify Session Created with ClientID.
    [Arguments]  ${client_id}  ${session_id}

    ${sessions}=  Redfish.Get Properties  /redfish/v1/SessionService/Sessions/${session_id}
    Rprint Vars  sessions
    @{words} =  Split String  ${sessions["Oem"]["OpenBMC"]["ClientOriginIP"]}  :
    ${ipaddr}=  Get Running System IP
    ${ipaddr}=  Convert To String  ${ipaddr}
    Set Test Variable  ${temp_ipaddr}  ${words}[-1]
    Valid Value  sessions["Id"]  ['${session_id}']
    Valid Value  sessions["Oem"]["OpenBMC"]["ClientID"]  ['${client_id}']
    Should Be Equal As Strings  ${ipaddr.strip()}  ${temp_ipaddr}


Suite Setup Execution
    [Documentation]  Suite setup execution.

    Redfish.Login


Test Teardown Execution
    [Documentation]  Test teardown execution.

    FFDC On Test Case Fail


Suite Teardown Execution
    [Documentation]  Suite teardown execution.

    Delete All Redfish Sessions
