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

    ## Members can be one or more, hence checking in the list
    ${payload}=  Create Dictionary  @odata.id=/redfish/v1/Managers/bmc
    List Should Contain Value  ${managers['Members']}  ${payload}


Verify BMC Version
    [Documentation]  Verify BMC Version.
    [Tags]  Verify_BMC_Version

    ${bmc_version}=  Get BMC Version
    ${bmc}=  Redfish.Get Properties  /redfish/v1/Managers/bmc
    Should Be Equal As Strings  "${bmc['FirmwareVersion']}"  ${bmc_version}


Verify BMC DateTime
    [Documentation]  Verify bmc DateTime.
    [Tags]  Verify_BMC_DateTime

    ${bmc}=  Redfish.Get Properties  /redfish/v1/Managers/bmc
    ${bmc_time_cli}=  Get Time Stamp

    ##  Convert this time-stamp to GMT to allign with DateTime timezone of Redfish interface
    ${time_gmt}=  Add Time To Date  ${bmc_time_cli}  6 hours
    ${time_gmt}=  Convert Date  ${time_gmt}  result_format=%Y-%m-%d %H:%M:%S.%f

    #  Example:  time_gmt =  2020-01-14 09:18:44.367
    #  Substring 0-16 will have  2020-01-14 09:18 i,e till minutes

    ${time_gmt_custom}=  Get Substring  ${time_gmt}  0  16

    ${time_redfish}=  Convert Date  ${bmc['DateTime']}  result_format=%Y-%m-%d %H:%M:%S.%f
    ${time_redfish_custom}=  Get Substring  ${time_redfish}  0  16

    ${status}=  Run Keyword And Return Status  Should Be Equal As Strings
    ...  ${time_gmt_custom}  ${time_redfish_custom}

    Pass Execution If  ${status} == ${True}  Time Matched

    ##  Minutes may differ based on the moment we read time on BMC ad via REST, hence add 1 minute
    ${time_gmt}=  Add Time To Date  ${time_gmt}  1 minute
    ${time_gmt}=  Convert Date  ${time_gmt}  result_format=%Y-%m-%d %H:%M:%S.%f

    ${time_gmt_custom}=  Get Substring  ${time_gmt}  0  16
    Should Be Equal As Strings  ${time_gmt_custom}  ${time_redfish_custom}


Verify Manager BMC Defaults
    [Documentation]  Verify manager bmc defaults.
    [Tags]    Verify_Manager_BMC_Defaults

    ${bmc}=  Redfish.Get Properties  /redfish/v1/Managers/bmc

    ${actions}=              Set Variable  ${bmc['Actions']}
    ${reset}=                Set Variable  ${actions['#Manager.Reset']}
    ${eth_interfaces}=       Set Variable  ${bmc['EthernetInterfaces']}
    ${graph_console}=        Set Variable  ${bmc['GraphicalConsole']}
    ${links}=                Set Variable  ${bmc['Links']}
    ${chassis_link}=         Set Variable  ${links['ManagerForChassis']}[0]
    ${servers_link}=         Set Variable  ${links['ManagerForServers']}[0]
    ${log_services}=         Set Variable  ${bmc['LogServices']}
    ${nw_protocol}=          Set Variable  ${bmc['NetworkProtocol']}
    ${ser_console}=          Set Variable  ${bmc['SerialConsole']}
    ${status}=               Set Variable  ${bmc['Status']}
    ${oem}=                  Set Variable  ${bmc['Oem']}
    ${openbmc}=              Set Variable  ${oem['OpenBmc']}
    ${certs}=                Set Variable  ${openbmc['Certificates']}

    ${chassis_cnt}=  Get Length  ${chassis_link}
    ${servers_cnt}=  Get Length  ${servers_link}

    Rprint Vars  bmc  reset  eth_interfaces  graph_console  links  chassis_link  servers_link  log_services
    ...  nw_protocol  ser_console  status  oem  openbmc  certs

    Valid Value  bmc['@odata.context']  ['/redfish/v1/$metadata#Manager.Manager']
    Valid Value  bmc['Name']  ['OpenBmc Manager']
    Valid Value  bmc['@odata.id']  ['/redfish/v1/Managers/bmc']
    Valid Value  bmc['@odata.type']  ['#Manager.v1_3_0.Manager']
    Valid Value  bmc['Id']  ['bmc']
    Valid Value  bmc['Description']  ['Baseboard Management Controller']
    Valid Value  bmc['ManagerType']  ['BMC']
    Valid Value  bmc['Model']  [OpenBmc']

    Valid Value  reset['ResetType@Redfish.AllowableValues']  [['GracefulRestart']]
    Valid Value  reset['target']  ['/redfish/v1/Managers/bmc/Actions/Manager.Reset']

    Valid Value  graph_console['ConnectTypesSupported']  [['KVMIP']]
    Valid Value  graph_console['ServiceEnabled']  [${True}]

    Valid Value  chassis_link['@odata.id']  ['/redfish/v1/Chassis/chassis']
    Valid Value  servers_link['@odata.id']  ['/redfish/v1/Systems/system']

    Valid Value  links['ManagerForChassis@odata.count']  [${${chassis_cnt}}]
    Valid Value  links['ManagerForServers@odata.count']  [${${servers_cnt}}]

    Valid Value  log_services['@odata.id']  ['/redfish/v1/Managers/bmc/LogServices']
    Valid Value  nw_protocol['@odata.id']  ['/redfish/v1/Managers/bmc/NetworkProtocol']
    Valid Value  eth_interfaces['@odata.id']  ['/redfish/v1/Managers/bmc/EthernetInterfaces']

    Valid Value  ser_console['ConnectTypesSupported']  [['IPMI', 'SSH']]
    Valid Value  ser_console['ServiceEnabled']  [${True}]

    Valid Value  status['Health']  ['OK']
    Valid Value  status['HealthRollup']  ['OK']
    Valid Value  status['State']  ['Enabled']

    Valid Value  oem['@odata.context']  ['/redfish/v1/$metadata#OemManager.Oem']
    Valid Value  oem['@odata.id']  ['/redfish/v1/Managers/bmc#/Oem']
    Valid Value  oem['@odata.type']  ['#OemManager.Oem']

    Valid Value  openbmc['@odata.context']  ['/redfish/v1/$metadata#OemManager.OpenBmc']
    Valid Value  openbmc['@odata.id']  ['/redfish/v1/Managers/bmc#/Oem/OpenBmc']
    Valid Value  openbmc['@odata.type']  ['#OemManager.OpenBmc']
    Valid Value  certs['@odata.id']  ['/redfish/v1/Managers/bmc/Truststore/Certificates']


Verify Session Persistency After BMC Reboot
    [Documentation]  Verify session persistency after BMC reboot.
    [Tags]  Verify_Session_Persistency_After_BMC_Reboot

    ## Note the current session location
    ${session_location}=  Redfish.Get Session Location

    Redfish OBMC Reboot (off)  stack_mode=normal
    Redfish.Login

    ## Check for session persistency after BMC reboot
    ##  sessions here will have list of all sessions location
    ${sessions}=  Redfish.Get Attribute  /redfish/v1/SessionService/Sessions  Members
    ${payload}=  Create Dictionary  @odata.id=${session_location}

    List Should Contain Value  ${sessions}  ${payload}


Verify Session Deletion
    [Documentation]  Verify session deletion.
    [Tags]  Verify_Session_Deletion

    ## Note the current session location
    ${session_location}=  Redfish.Get Session Location

    ##  Delete the current session and re-Login
    Redfish.Logout
    Redfish.Login

    ${sessions}=  Redfish.Get Attribute  /redfish/v1/SessionService/Sessions  Members
    ${payload}=  Create Dictionary  @odata.id=${session_location}

    ## Make sure previous session is really deleted
    List Should Not Contain Value  ${sessions}  ${payload}


REST Logging Interface Read Should Be A SUCCESS For Authorized Users
    [Documentation]  REST logging interface read should be a success for authorized users.
    [Tags]    REST_Logging_Interface_Read_Should_Be_A_SUCCESS_For_Authorized_Users

    ${resp}=  Redfish.Get  /xyz/openbmc_project/logging

    ${resp_output}=  evaluate  json.loads('''${resp.text}''')  json
    ${log_count}=  Get Length  ${resp_output["data"]}

    ##  Max 200 error logs are allowed in OpenBmc
    Run Keyword Unless   ${-1} < ${log_count} < ${201}  Fail


##  Immediate next test case will be maintained as last test in this suite.
##  Hence Redfish.Login is not called at the end
REST Logging Interface Read Should Throw Un-Authorized Response For Null Token
    [Documentation]  REST Logging Interface Read Should Throw Un-Authorized Response For Null Token.
    [Tags]    REST_Logging_Interface_Read_Should_Throw_Un-Authorized_Response_For_Null_Token

    Redfish.Logout
    Redfish.Get  /xyz/openbmc_project/logging  valid_status_codes=[${HTTP_UNAUTHORIZED}]


