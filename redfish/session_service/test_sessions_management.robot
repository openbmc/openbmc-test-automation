*** Settings ***
Documentation    Test Redfish SessionService.

Resource         ../../lib/resource.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/openbmc_ffdc.robot

Suite Setup      Redfish.Login
Suite Teardown   Redfish.Logout
Test Setup       Printn
Test Teardown    FFDC On Test Case Fail


*** Test Cases ***

Verify HTTP_CREATED Response From Session Creation Request
    [Documentation]  Verify HTTP_CREATED response from session creation request.
    [Tags]  Verify_HTTP_CREATED_Response_From_Session_Creation_Request

    Redfish.Post  /redfish/v1/SessionService/Sessions
    ...  body={'UserName':'${OPENBMC_USERNAME}', 'Password': '${OPENBMC_PASSWORD}'}
    ...  valid_status_codes=[${HTTP_CREATED}]


Verify SessionService Defaults
    [Documentation]  Verify SessionService default property values.
    [Tags]  Verify_SessionService_Defaults

    ${session_service}=  Redfish.Get Properties  /redfish/v1/SessionService
    Rprint Vars  session_service

    Valid Value  session_service['@odata.context']  ['/redfish/v1/$metadata#SessionService.SessionService']
    Valid Value  session_service['@odata.id']  ['/redfish/v1/SessionService/']
    Valid Value  session_service['Description']  ['Session Service']
    Valid Value  session_service['Id']  ['SessionService']
    Valid Value  session_service['Name']  ['Session Service']
    Valid Value  session_service['ServiceEnabled']  [True]
    Valid Value  session_service['SessionTimeout']  [3600]
    Valid Value  session_service['Sessions']['@odata.id']  ['/redfish/v1/SessionService/Sessions']


Verify Sessions Defaults
    [Documentation]  Verify Sessions default property values.
    [Tags]  Verify_Sessions_Defaults

    ${sessions}=  Redfish.Get Properties  /redfish/v1/SessionService/Sessions
    Rprint Vars  sessions
    ${sessions_count}=  Get length  ${sessions['Members']}

    Valid Value  sessions['@odata.context']  ['/redfish/v1/$metadata#SessionCollection.SessionCollection']
    Valid Value  sessions['@odata.id']  ['/redfish/v1/SessionService/Sessions/']
    Valid Value  sessions['Description']  ['Session Collection']
    Valid Value  sessions['Name']  ['Session Collection']
    Valid Value  sessions['Members@odata.count']  [${sessions_count}]


Verify Current Session Defaults
    [Documentation]  Verify Current session default property values.
    [Tags]  Verify_Current_Session_Defaults

    ${session_location}=  Redfish.Get Session Location
    ${session_id}=  Evaluate  os.path.basename($session_location)  modules=os
    ${session_properties}=  Redfish.Get Properties  /redfish/v1/SessionService/Sessions/${session_id}
    Rprint Vars  session_location  session_id  session_properties

    Valid Value  session_properties['@odata.context']  ['/redfish/v1/$metadata#Session.Session']
    Valid Value  session_properties['@odata.id']  ['/redfish/v1/SessionService/Sessions/${session_id}']
    Valid Value  session_properties['Description']  ['Manager User Session']
    Valid Value  session_properties['Name']  ['User Session']
    Valid Value  session_properties['Id']  ['${session_id}']
    Valid Value  session_properties['UserName']  ['${OPENBMC_USERNAME}']


Verify Managers Defaults
    [Documentation]  Verify managers defaults.
    [Tags]  Verify_Managers_Defaults

    ${managers}=  Redfish.Get Properties  /redfish/v1/Managers
    Rprint Vars  managers
    ${managers_count}=  Get Length  ${managers['Members']}

    Valid Value  managers['@odata.context']  ['/redfish/v1/$metadata#ManagerCollection.ManagerCollection']
    Valid Value  managers['Name']  ['Manager Collection']
    Valid Value  managers['@odata.id']  ['/redfish/v1/Managers']
    Valid Value  managers['Members@odata.count']  [${managers_count}]

    # Members can be one or more, hence checking in the list
    Valid List  managers['Members']  required_values=[{'@odata.id': '/redfish/v1/Managers/bmc'}]


Verify Chassis Defaults
    [Documentation]  Verify chassis defaults.
    [Tags]  Verify_Chassis_Defaults

    ${chassis}=  Redfish.Get Properties  /redfish/v1/Chassis
    Rprint Vars  chassis
    ${chassis_count}=  Get Length  ${chassis['Members']}

    Valid Value  chassis['@odata.context']  ['/redfish/v1/$metadata#ChassisCollection.ChassisCollection']
    Valid Value  chassis['Name']  ['Chassis Collection']
    Valid Value  chassis['@odata.id']  ['/redfish/v1/Chassis']
    Valid Value  chassis['Members@odata.count']  [${chassis_count}]
    Valid Value  chassis['Members@odata.count']  [${chassis_count}]

    # Members can be one or more, hence checking in the list
    Log To Console  ${chassis['Members']}
    Valid List  chassis['Members']
    ...  required_values=[{'@odata.id': '/redfish/v1/Chassis/chassis'}]


Verify Systems Defaults
    [Documentation]  Verify systems defaults.
    [Tags]  Verify_Systems_Defaults

    ${systems}=  Redfish.Get Properties  /redfish/v1/Systems
    Rprint Vars  systems
    ${systems_count}=  Get Length  ${systems['Members']}

    Valid Value  systems['@odata.context']
    ...  ['/redfish/v1/$metadata#ComputerSystemCollection.ComputerSystemCollection']
    Valid Value  systems['Name']  ['Computer System Collection']
    Valid Value  systems['@odata.id']  ['/redfish/v1/Systems']
    Valid Value  systems['Members@odata.count']  [${systems_count}]
    Valid Value  systems['Members@odata.count']  [${systems_count}]
    # Members can be one or more, hence checking in the list
    Valid List  systems['Members']  required_values=[{'@odata.id': '/redfish/v1/Systems/system'}]


Verify BMC Version
    [Documentation]  Verify BMC Version.
    [Tags]  Verify_BMC_Version

    ${bmc_version}=  Get BMC Version
    ${bmc}=  Redfish.Get Properties  /redfish/v1/Managers/bmc
    Should Be Equal As Strings  "${bmc['FirmwareVersion']}"  ${bmc_version}


Verify Session Persistency After BMC Reboot
    [Documentation]  Verify session persistency after BMC reboot.
    [Tags]  Verify_Session_Persistency_After_BMC_Reboot

    # Note the current session location
    ${session_location}=  Redfish.Get Session Location

    Redfish OBMC Reboot (off)  stack_mode=normal
    Redfish.Login

    # Check for session persistency after BMC reboot
    # sessions here will have list of all sessions location
    ${sessions}=  Redfish.Get Attribute  /redfish/v1/SessionService/Sessions  Members
    ${payload}=  Create Dictionary  @odata.id=${session_location}

    List Should Contain Value  ${sessions}  ${payload}


Verify Session Deletion
    [Documentation]  Verify session deletion.
    [Tags]  Verify_Session_Deletion

    # Note the current session location
    ${session_location}=  Redfish.Get Session Location

    # Delete the current session and re-Login
    Redfish.Logout
    Redfish.Login

    ${sessions}=  Redfish.Get Attribute  /redfish/v1/SessionService/Sessions  Members
    ${payload}=  Create Dictionary  @odata.id=${session_location}

    # Make sure previous session is really deleted
    List Should Not Contain Value  ${sessions}  ${payload}


REST Logging Interface Read Should Be A SUCCESS For Authorized Users
    [Documentation]  REST logging interface read should be a success for authorized users.
    [Tags]    REST_Logging_Interface_Read_Should_Be_A_SUCCESS_For_Authorized_Users

    ${resp}=  Redfish.Get  /xyz/openbmc_project/logging

    ${resp_output}=  evaluate  json.loads('''${resp.text}''')  json
    ${log_count}=  Get Length  ${resp_output["data"]}

    # Max 200 error logs are allowed in OpenBmc
    Run Keyword Unless   ${-1} < ${log_count} < ${201}  Fail


# Immediate next test case will be maintained as last test in this suite.
# Hence Redfish.Login is not called at the end
REST Logging Interface Read Should Throw Un-Authorized Response For Null Token
    [Documentation]  REST Logging Interface Read Should Throw Un-Authorized Response For Null Token.
    [Tags]    REST_Logging_Interface_Read_Should_Throw_Un-Authorized_Response_For_Null_Token

    Redfish.Logout
    Redfish.Get  /xyz/openbmc_project/logging  valid_status_codes=[${HTTP_UNAUTHORIZED}]


