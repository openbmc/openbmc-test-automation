*** Settings ***

Documentation     Test client identifier feature on BMC.

Resource          ../../lib/rest_client.robot
Resource          ../../lib/openbmc_ffdc.robot
Resource          ../../lib/resource.robot
Resource          ../../lib/bmc_redfish_utils.robot
Library           ../../lib/bmc_network_utils.py
Library           ../../lib/gen_robot_valid.py

Suite Setup       Redfish.Login
Suite Teardown    Run Keyword And Ignore Error  Delete All Redfish Sessions
Test Setup        Printn
Test Teardown     FFDC On Test Case Fail


*** Test Cases ***

Create A Session With ClientID And Verify
    [Documentation]  Create a session with client id and verify client id is same.
    [Tags]  Create_A_Session_With_ClientID_And_Verify
    [Template]  Create And Verify Session ClientID

    # client_id           reboot_flag
    12345                 False
    123456                False
    EXTERNAL-CLIENT-01    False
    EXTERNAL-CLIENT-02    False


Check ClientID Persistency On BMC Reboot
    [Documentation]  Create a session with client id and verify client id is same after the reboot.
    [Tags]  Check_ClientID_Persistency_On_BMC_Reboot
    [Template]  Create And Verify Session ClientID

    # client_id           reboot_flag
    12345                 True
    EXTERNAL-CLIENT-01    True


Create A Multiple Session With ClientID And Verify
    [Documentation]  Create a multiple session with client id and verify client id is same.
    [Tags]  Create_A_Multiple_Session_With_ClientID_And_Verify
    [Template]  Create And Verify Session ClientID

    # client_id                              reboot_flag
    12345,123456                             False
    EXTERNAL-CLIENT-01,EXTERNAL-CLIENT-02    False


Check Multiple ClientID Persistency On BMC Reboot
    [Documentation]  Create a multiple session with client id and verify client id is same after the reboot.
    [Tags]  Check_Multiple_ClientID_Persistency_On_BMC_Reboot
    [Template]  Create And Verify Session ClientID

    # client_id                              reboot_flag
    12345,123456                             True
    EXTERNAL-CLIENT-01,EXTERNAL-CLIENT-02    True


Fail To Set Client Origin IP
    [Documentation]  Fail to set the client origin IP.
    [Tags]  Fail_To_Set_Client_Origin_IP
    [Template]  Create Session And Fail To Set Client Origin IP

    # client_id
    12345
    EXTERNAL-CLIENT-01


Create Session For Non Admin User
    [Documentation]  Create Session for non-admin user.
    [Tags]  Create_Session_For_Non_Admin_User
    [Template]  Non Admin User To Create Session

    # client_id    username         password      role_id
    12345          operator_user    TestPwd123    Operator


*** Keywords ***

Create A Session With ClientID
    [Documentation]  Create redifish session with client id.
    [Arguments]  ${client_id}

    # Description of argument(s):
    # client_id    This client id can contain string value
    #              (e.g. 12345, "EXTERNAL-CLIENT").

    @{session_list}=  Create List
    &{tmp_dict}=  Create Dictionary

    FOR  ${client}  IN  @{client_id}
      ${resp}=  Redfish Login  kwargs= "Oem":{"OpenBMC" : {"ClientID":"${client}"}}
      Append To List  ${session_list}  ${resp}
    END

    [Return]  ${session_list}


Get Session Information By ClientID
    [Documentation]  Get session information by client id.
    [Arguments]  ${client_id}  ${session_ids}

    FOR  ${session}  IN  @{session_ids}
       Return From Keyword If  '${client_id}' == '${session["Oem"]["OpenBMC"]["ClientID"]}'  ${session["Id"]}
    END

    [Return]  ${EMPTY}


Verify A Session Created With ClientID
    [Documentation]  Verify session created with client id.
    [Arguments]  ${client_ids}  ${session_ids}

    # Description of argument(s):
    # client_id    External client name.
    # session_id   This value is a session id.

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

    FOR  ${client}  IN  @{client_ids}
      ${session_id}=  Get Session Information By ClientID  ${client}  ${session_ids}
      ${sessions}=  Redfish.Get Properties  /redfish/v1/SessionService/Sessions/${session_id}
      Rprint Vars  sessions
      @{words} =  Split String  ${sessions["ClientOriginIPAddress"]}  :
      ${ip_address}=  Get Running System IP
      Set Test Variable  ${temp_ipaddr}  ${words}[-1]
      Valid Value  client  ['${sessions["Oem"]["OpenBMC"]["ClientID"]}']
      Valid Value  sessions["Id"]  ['${session_id}']
      Valid Value  temp_ipaddr  ${ip_address}
    END


Create And Verify Session ClientID
    [Documentation]  Create redifish session with client id and verify it remain same.
    [Arguments]  ${client_id}  ${reboot_flag}=False

    # Description of argument(s):
    # client_id    This client id contain string value
    #              (e.g. 12345, "EXTERNAL-CLIENT").
    # reboot_flag  Flag is used to run reboot the BMC code.
    #               (e.g. True or False).

    ${client_ids}=  Split String  ${client_id}  ,
    ${session_info}=  Create A Session With ClientID  ${client_ids}
    Verify A Session Created With ClientID  ${client_ids}  ${session_info}
    Run Keyword If  '${reboot_flag}' == 'True'
    ...  Run Keywords  Redfish OBMC Reboot (off)  AND
    ...  Verify A Session Created With ClientID  ${client_ids}  ${session_info}


Set Client Origin IP
    [Documentation]  Set client origin IP.
    [Arguments]  ${client_id}  ${client_ip}  ${status}

    # Description of argument(s):
    # client_id    This client id contain string value
    #              (e.g. 12345, "EXTERNAL-CLIENT").
    # client_ip    Valid IP address
    # status       HTTP status code

    ${session}=  Run Keyword And Return Status
    ...  Redfish Login
    ...  kwargs= "Oem":{"OpenBMC": {"ClientID":"${client_id}", "ClientOriginIP":"${client_ip}"}}
    Valid Value  session  [${status}]


Create Session And Fail To Set Client Origin IP
    [Documentation]  Create redifish session with client id and fail to set client origin IP.
    [Arguments]  ${client_id}

    # Description of argument(s):
    # client_id    This client id contain string value
    #              (e.g. 12345, "EXTERNAL-CLIENT").

    Set Test Variable  ${client_ip}  10.6.7.8
    ${resp}=  Set Client Origin IP  ${client_id}  ${client_ip}  status=False


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
    # client_id    External client name.
    # session_id   This value is a session id.

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

    FOR  ${client}  IN  @{client_ids}
      ${session_id}=  Get Session Information By ClientID  ${client}  ${session_ids}
      ${resp}=  Redfish Get Request  /redfish/v1/SessionService/Sessions/${session_id}
      ${sessions}=     To Json    ${resp.content}
      #Set Test Variable  ${sessions}  ${content["data"]}
      Rprint Vars  sessions
      Log  ${sessions}
      @{words} =  Split String  ${sessions["ClientOriginIPAddress"]}  :
      ${ip_address}=  Get Running System IP
      Set Test Variable  ${temp_ipaddr}  ${words}[-1]
      Valid Value  client  ['${sessions["Oem"]["OpenBMC"]["ClientID"]}']
      Valid Value  sessions["Id"]  ['${session_id}']
      Valid Value  temp_ipaddr  ${ip_address}
    END


Non Admin User To Create Session
    [Documentation]  Non Admin user create a session and verify the session is created.
    [Arguments]  ${client_id}  ${username}  ${password}  ${role}  ${enabled}=${True}

    # Description of argument(s):
    # client_id    This client id contain string value
    #              (e.g. 12345, "EXTERNAL-CLIENT").
    # username     Username.
    # password     Password.
    # role         Role of user.
    # enabled      Value can be True or False.

    Redfish.Login
    Redfish Create User  ${username}  ${password}  ${role}  ${enabled}
    Delete All Sessions
    Redfish.Logout
    Initialize OpenBMC  rest_username=${username}  rest_password=${password}
    ${client_ids}=  Split String  ${client_id}  ,
    ${session_info}=  Create A Non Admin Session With ClientID  ${client_ids}  ${username}  ${password}
    Verify A Non Admin Session Created With ClientID  ${client_ids}  ${session_info}
