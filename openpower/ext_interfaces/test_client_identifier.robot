*** Settings ***

Documentation     Test client identifier feature on BMC.

Resource          ../../lib/rest_client.robot
Resource          ../../lib/openbmc_ffdc.robot
Resource          ../../lib/resource.robot
Resource          ../../lib/bmc_redfish_utils.robot
Resource          ../../lib/external_intf/management_console_utils.robot
Resource          ../../lib/utils.robot
Library           ../../lib/bmc_network_utils.py
Library           ../../lib/gen_robot_valid.py
Resource          ../../lib/bmc_redfish_resource.robot
Resource          ../../lib/redfish_request.robot
#Library           ../../lib/redfish_request.py
#Library           ../../lib/test.py
#Library           test.PrintClass
#Library           redfish_request.RedfishRequest

Suite Setup       Run Keyword And Ignore Error  Delete All Redfish Sessions
Suite Teardown    Run Keyword And Ignore Error  Delete All Redfish Sessions
Test Setup        Printn
Test Teardown     Run Keywords  Delete All Redfish Sessions  AND  FFDC On Test Case Fail


*** Variables ***
${active_session_info}
@{session_dict_list}

*** Test Cases ***

Create A Session With ClientID And Verify
    [Documentation]  Create a session with client id and verify client id is same.
    [Tags]  Create_A_Session_With_ClientID_And_Verify
    [Template]  Create And Verify Session ClientID

    # reboot_flag
    False


Check ClientID Persistency On BMC Reboot
    [Documentation]  Create a session with client id and verify client id is same after the reboot.
    [Tags]  Check_ClientID_Persistency_On_BMC_Reboot
    [Template]  Create And Verify Session ClientID

    # reboot_flag
    True


Create A Multiple Session With ClientID And Verify
    [Documentation]  Create a multiple session with client id and verify client id is same.
    [Tags]  Create_A_Multiple_Session_With_ClientID_And_Verify
    [Template]  Create And Verify Multiple Session ClientID

    reboot_flag
    False


Check Multiple ClientID Persistency On BMC Reboot
    [Documentation]  Create a multiple session with client id and verify client id is same after the reboot.
    [Tags]  Check_Multiple_ClientID_Persistency_On_BMC_Reboot
    [Template]  Create And Verify Multiple Session ClientID

    reboot_flag
    True


Fail To Set Client Origin IP
    [Documentation]  Fail to set the client origin IP.
    [Tags]  Fail_To_Set_Client_Origin_IP

    Set Test Variable  ${uri}   /redfish/v1/SessionService/Sessions
    Set Test Variable  ${client_ip}  10.6.7.8

    ${headers}=  Create Dictionary

    Set Test Variable  ${active_session_info['headers']}  ${headers}
    Log  ${active_session_info}
    ${oem_id}=  GenerateOEMId
    ${temp}=  Create Dictionary  ClientID=${oem_id}
    Set To Dictionary  ${temp}  ClientOriginIP  ${client_ip}
    ${temp}=  Create Dictionary  OpenBMC=${temp}
    ${data}=  Create Dictionary  UserName=${OPENBMC_USERNAME}  Password=${OPENBMC_PASSWORD}  Oem=${temp}

    ${resp}=  Redfish POST Request URI  ${active_session_info['headers']}  ${uri}  ${data}  status_code=${HTTP_BAD_REQUEST}


Create Session For Non Admin User
    [Documentation]  Create Session for non-admin user.
    [Tags]  Create_Session_For_Non_Admin_User
    [Template]  Non Admin User To Create Session

    # username       password      role_id
    operator_user    TestPwd123    Operator


*** Keywords ***

Create And Verify Session ClientID
    [Documentation]  Create redifish session with client id and verify it remain same.
    [Arguments]  ${reboot_flag}=False

    # Description of argument(s):
    # client_id    This client id contain string value
    #              (e.g. 12345, "EXTERNAL-CLIENT").
    # reboot_flag  Flag is used to run reboot the BMC code.
    #               (e.g. True or False).

    ${admin_session}=  Redfish Generic Session Request  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}
    Verify Redfish Generic Session  ${admin_session}
    
    Run Keyword If  '${reboot_flag}' == 'True'
    ...  Run Keywords  Redfish Request BMC Reset Operation  AND
    ...  Sleep  30s  AND
    ...  Check BMC At Standby  AND
    ...  Verify Redfish Generic Session  ${admin_session}

    Redfish Request Delete Session  ${admin_session}


Create And Verify Multiple Session ClientID
    [Documentation]  Create redifish session with client id and verify it remain same.
    [Arguments]  ${reboot_flag}=False

    # Description of argument(s):
    # client_id    This client id contain string value
    #              (e.g. 12345, "EXTERNAL-CLIENT").
    # reboot_flag  Flag is used to run reboot the BMC code.
    #               (e.g. True or False).

    ${admin_session_1}=  Redfish Generic Session Request  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}
    Verify Redfish Generic Session  ${admin_session_1}
    ${admin_session_2}=  Redfish Generic Session Request  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}
    Verify Redfish Generic Session  ${admin_session_2}

    Run Keyword If  '${reboot_flag}' == 'True'
    ...  Run Keywords  Redfish Request BMC Reset Operation  AND
    ...  Sleep  30s  AND
    ...  Check BMC At Standby  AND
    ...  Verify Redfish Generic Session  ${admin_session_1}  AND
    ...  Verify Redfish Generic Session  ${admin_session_2}

    Redfish Request Delete Session  ${admin_session_1}
    Redfish Request Delete Session  ${admin_session_2}


Create Session And Fail To Set Client Origin IP
    [Documentation]  Create redifish session with client id and fail to set client origin IP.

    # Description of argument(s):
    # client_id    This client id contain string value
    #              (e.g. 12345, "EXTERNAL-CLIENT").


    Set Test Variable  ${uri}   /redfish/v1/SessionService/Sessions
    Set Test Variable  ${client_ip}  10.6.7.8

    ${headers}=  Create Dictionary

    Set Global Variable  ${active_session_info['headers']}  ${headers}
    Log  ${active_session_info}
    ${oem_id}=  GenerateOEMId
    ${temp}=  Create Dictionary  ClientID=${oem_id}
    Set To Dictionary  ${temp}  ClientOriginIP  ${client_ip}
    ${temp}=  Create Dictionary  OpenBMC=${temp}
    ${data}=  Create Dictionary  UserName=${OPENBMC_USERNAME}  Password=${OPENBMC_PASSWORD}  Oem=${temp}

    ${resp}=  Redfish POST Request URI  ${active_session_info['headers']}  ${uri}  ${data}  status_code=${HTTP_BAD_REQUEST}


Create A Non Admin Session With ClientID
    [Documentation]  Create redifish session with client id.
    [Arguments]  ${client_id}  ${username}  ${password}

    # Description of argument(s):
    # client_id    This client id can contain string value
    #              (e.g. 12345, "EXTERNAL-CLIENT").

    @{session_list}=  Create List
    &{tmp_dict}=  Create Dictionary

    FOR  ${client}  IN  @{client_id}
      ${resp}=  Redfish Login  rest_username=${username}  rest_password=${password}  kwargs= "Oem":{"OpenBMC" : {"ClientID":"${client}"}}
      Append To List  ${session_list}  ${resp}
    END

    [Return]  ${session_list}


Verify A Non Admin Session Created With ClientID
    [Documentation]  Verify session created with client id.
    [Arguments]  ${client_ids}  ${session_ids}

    # Description of argument(s):
    # client_ids    External client name.
    # session_ids   This value is a session id.

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

    FOR  ${client}  ${session}  IN ZIP  ${client_ids}  ${session_ids}
      ${resp}=  Redfish Get Request  /redfish/v1/SessionService/Sessions/${session["Id"]}
      ${sessions}=     To Json    ${resp.content}
      Rprint Vars  sessions
      @{words} =  Split String  ${sessions["ClientOriginIPAddress"]}  :
      ${ip_address}=  Get Running System IP
      Set Test Variable  ${temp_ipaddr}  ${words}[-1]
      Valid Value  client  ['${sessions["Oem"]["OpenBMC"]["ClientID"]}']
      Valid Value  session["Id"]  ['${sessions["Id"]}']
      Valid Value  temp_ipaddr  ${ip_address}
    END


Non Admin User To Create Session
    [Documentation]  Non Admin user create a session and verify the session is created.
    [Arguments]  ${username}  ${password}  ${role}  ${enabled}=${True}

    # Description of argument(s):
    # client_id    This client id contain string value
    #              (e.g. 12345, "EXTERNAL-CLIENT").
    # username     Username.
    # password     Password.
    # role         Role of user.
    # enabled      Value can be True or False.


    ${admin_session}=  Redfish Generic Session Request  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}
    Log  ${active_session_info}
    Log  ${session_dict_list}
    Verify Redfish Generic Session  ${admin_session}

    Redfish Request Create User  ${username}  ${password}  ${role}  ${enabled}
    ${operator_session}=  Redfish Generic Session Request  ${username}  ${password}
    Verify Redfish Generic Session  ${operator_session}

    ${curr_role}=  Run Keyword And Ignore Error  Redfish Request Get User Role  ${user_name}
    ${user_exists}=  Run Keyword And Return Status  Should Be Equal As Strings  ${curr_role}[0]  PASS
    Log  ${active_session_info}
    Log  ${session_dict_list}
    Set Global Variable  ${active_session_info}  ${admin_session}
    Run Keyword If  ${user_exists} == ${True}
    ...  Run Keywords  Set Test Variable  ${uri}  ${REDFISH_ACCOUNTS_URI}${user_name}  AND
    ...  Redfish DELETE Request URI  ${active_session_info['headers']}  ${uri}
    
    Redfish Request Delete Session  ${operator_session}
    Redfish Request Delete Session  ${admin_session}
