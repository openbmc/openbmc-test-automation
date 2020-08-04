*** Settings ***

Documentation     Test KYC feature on BMC.

Resource          ../../lib/rest_client.robot
Resource          ../../lib/openbmc_ffdc.robot
Resource          ../../lib/resource.robot
Resource          ../../lib/bmc_redfish_utils.robot
Resource          ../../lib/utils.robot
Resource          ../../lib/boot_utils.robot
Library           ../../lib/code_update_utils.py
Library           ../../lib/gen_robot_valid.py

Suite Setup       Redfish.Login
Suite Teardown    Delete All Redfish Sessions
Test Setup        Printn
Test Teardown     FFDC On Test Case Fail


*** Test Cases ***

Redfish Session With ClientID
   [Documentation]  Create a session with client id and verify client id is same.
   [Tags]  Redfish_Session_With_ClientID
   [Template]  Create Redfish Session With ClientID

   #ClientID
   12345
   123456
   HMCID-01
   HMCID-02


Check Redfish Session With ClientID Persistency
   [Documentation]  Create a session with client id and verify client id is same after the reboot.
   [Tags]  Check_Redfish_Session_With_ClientID_Persistency
   [Template]  Redfish Persistence Session With ClientID

   #ClientID
   12345
   HMCID-01

*** Keywords ***

Create Redfish Session With ClientID
    [Documentation]  Create redifish session with client id.
    [Arguments]  ${client_id}

    # Description of argument(s):
    # client_id    This client id can contain string value
    #              (e.g. 12345, "HMCID").

    ${resp}=  Redfish Login  kwargs= "Oem":{"OpenBMC" : {"ClientID":"${client_id}"}}
    Set Test Variable  ${session_id}  ${resp['Id']}
    Verify Redfish Session Created With ClientID  ${client_id}  ${session_id}


Verify Redfish Session Created With ClientID
    [Documentation]  verify Session Created with ClientID.
    [Arguments]  ${client_id}  ${session_id}

    # Description of argument(s):
    # client_id    This client id can contain string value
    #              (e.g. 12345, "HMCID").
    # session_id   This value is a session id.

    ${sessions}=  Redfish.Get Properties  /redfish/v1/SessionService/Sessions/${session_id}

    # {
    #   "@odata.id": "/redfish/v1/SessionService/Sessions/H8q2ZKucSJ",
    #   "@odata.type": "#Session.v1_0_2.Session",
    #   "Description": "Manager User Session",
    #   "Id": "H8q2ZKucSJ",
    #   "Name": "User Session",
    #   "Oem": {
    #   "OpenBMC": {
    #  "@odata.type": "#OemSession.v1_0_0.Session",
    #  "ClientID": "",
    #  "ClientOriginIP": "::ffff:x.x.x.x"
    #       }
    #     },
    #   "UserName": "root"
    # }

    Rprint Vars  sessions
    @{words} =  Split String  ${sessions["Oem"]["OpenBMC"]["ClientOriginIP"]}  :
    ${ipaddr}=  Get Running System IP
    Set Test Variable  ${temp_ipaddr}  ${words}[-1]
    Valid Value  sessions["Id"]  ['${session_id}']
    Valid Value  temp_ipaddr  ${ipaddr}


Redfish Persistence Session With ClientID
    [Documentation]  Create redifish session with client id.
    [Arguments]  ${client_id}

    # Description of argument(s):
    # client_id    This client id can contain string value
    #              (e.g. 12345, "HMCID").

    Create Redfish Session With ClientID  ${client_id}
    Redfish OBMC Reboot (off)
    Verify Redfish Session Created With ClientID  ${client_id}  ${session_id} 
