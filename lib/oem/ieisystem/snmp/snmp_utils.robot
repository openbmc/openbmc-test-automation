*** Settings ***

Documentation  Utilities for SNMP testing.

Resource  ../../../../lib/rest_client.robot
Resource  ../../../../lib/utils.robot


*** Keywords ***

Configure SNMP Manager On BMC
    [Documentation]  Configure SNMP manager on BMC.
    [Arguments]  ${snmp_ip}  ${port}  ${id}  ${expected_result}

    # Description of argument(s):
    # snmp_ip          SNMP manager IP.
    # port             Network port where SNMP manager is listening.
    # expected_result  Expected status of SNMP configuration.

    ${snmp_mgr_data}=  Create Dictionary  Id=${id}  Enabled=${true}
    ...  Port=${port}  Destination=${snmp_ip}

    ${snmp_trap_manager}=  Create List  ${snmp_mgr_data}
    ${trap_server}=  Create Dictionary  TrapServer=${snmp_trap_manager}
    ${snmp_mgr_data}=  Create Dictionary  SnmpTrapNotification=${trap_server}

    ${valid_status_codes}=  Set Variable  ${HTTP_NO_CONTENT}
    IF  '${expected_result}' == 'error'
        ${valid_status_codes}=  Set Variable  ${HTTP_BAD_REQUEST}
    END

    ${resp}=  Redfish.Patch  ${subscription_uri}  body=&{snmp_mgr_data}
    ...  valid_status_codes=[${valid_status_codes}]


Get List Of SNMP Manager And Port Configured On BMC
    [Documentation]  Get list of SNMP managers and return the list.

    ${snmp_mgr_config}=  Redfish.Get Attribute  ${subscription_uri}  SnmpTrapNotification
    ${ret_config}=  Get From Dictionary  ${snmp_mgr_config}  TrapServer

    RETURN  ${ret_config}


Verify SNMP Manager
    [Documentation]  Verify SNMP manager configured on BMC.
    [Arguments]  ${snmp_ip}  ${port}  ${id}=${0}

    # Description of argument(s):
    # snmp_ip  SNMP manager IP.
    # port     Network port where SNMP manager is listening.
    # id  SNMP manager id, default value is 0.

    @{snmp_mgr_list}=  Get List Of SNMP Manager And Port Configured On BMC

    FOR  ${member}  IN  @{snmp_mgr_list}
        ${snmp_id}=  Get From Dictionary  ${member}  Id
        IF  ${id} == ${snmp_id}
            ${ip}=  Get From Dictionary  ${member}  Destination
            ${port}=  Get From Dictionary  ${member}  Port
            Should Be Equal  ${ip}  ${snmp_ip}
            ...  msg=SNMP manager is not configured.
            Should Be Equal  ${port}  ${port}
            ...  msg=SNMP manager is not configured.
            Exit For Loop
        END
    END


Reset SNMP Manager And Object
    [Documentation]  Delete SNMP manager.
    [Arguments]  ${snmp_ip}  ${port}  ${id}=${0}

    # Description of argument(s):
    # snmp_ip  SNMP manager IP.
    # port     Network port where SNMP manager is listening.
    # id      SNMP manager id, default value is 0.

    ${status}=  Run Keyword And Return Status
    ...  Configure SNMP Manager On BMC  ${snmp_ip}  ${port}  ${id}  Valid
    Should Be Equal  ${status}  ${True}
    ...  msg=SNMP manager is not reseted to default in the backend.


Start SNMP Manager
    [Documentation]  Start SNMP listener on the remote SNMP manager.

    Open Connection And Log In  ${SNMP_MGR1_USERNAME}  ${SNMP_MGR1_PASSWORD}
    ...  alias=snmp_server  host=${SNMP_MGR1_IP}

    # The execution of the SNMP_TRAPD_CMD is necessary to cause SNMP to begin
    # listening to SNMP messages.
    SSHLibrary.write  ${SNMP_TRAPD_CMD} &
