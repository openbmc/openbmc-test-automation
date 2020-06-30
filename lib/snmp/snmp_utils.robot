*** Settings ***
Documentation  Utilities for SNMP testing.

Resource  ../../lib/rest_client.robot
Resource  ../../lib/utils.robot

*** Keywords ***

Get SNMP URI List
    [Documentation]  Get all SNMP URIs and return them as list.

    # Sample output:
    #   "data": [
    #     "/xyz/openbmc_project/network/snmp/manager/e9767624",
    #     "/xyz/openbmc_project/network/snmp/manager/31f4ce8b"
    #   ],

    @{snmp_uri_list}=  Read Properties  ${SNMP_MANAGER_URI}

    [Return]  @{snmp_uri_list}

Configure SNMP Manager On BMC
    [Documentation]  Configure SNMP manager on BMC.
    [Arguments]  ${snmp_ip}  ${port}  ${expected_result}

    # Description of argument(s):
    # snmp_ip          SNMP manager IP.
    # port             Network port where SNMP manager is listening.
    # expected_result  Expected status of SNMP configuration.

    @{snmp_parm_list}=  Create List  ${snmp_ip}  ${port}
    ${data}=  Create Dictionary  data=@{snmp_parm_list}

    ${resp}=  OpenBMC Post Request
    ...  ${SNMP_MANAGER_URI}action/Client  data=${data}

    Run Keyword If  '${expected_result}' == 'error'
    ...      Should Be Equal As Strings
    ...      ${resp.status_code}  ${HTTP_BAD_REQUEST}
    ...      msg=Allowing the configuration of an invalid SNMP.
    ...  ELSE
    ...      Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    ...      msg=Not allowing the configuration of a valid SNMP.


Get List Of SNMP Manager And Port Configured On BMC
    [Documentation]  Get list of SNMP managers and return the list.

    @{snmp_uri_list}=  Get SNMP URI List
    @{ip_and_port_list}=  Create List

    # Sample output of snmp_uri_list enumeration.
    # {
    #  "data": {
    #    "/xyz/openbmc_project/network/snmp/manager/92ae7a66": {
    #      "Address": "10.6.6.6",
    #      "AddressFamily": "xyz.openbmc_project.Network.Client.IPProtocol.IPv4",
    #      "Port": 186
    #    },

    FOR  ${snmp_uri}  IN   @{snmp_uri_list}
      ${ip}=  Read Attribute  ${snmp_uri}  Address
      ${port}=  Read Attribute  ${snmp_uri}  Port
      Append To List  ${ip_and_port_list}  ${ip}  ${port}
    END

    [Return]  @{ip_and_port_list}


Verify SNMP Manager
    [Documentation]  Verify SNMP manager configured on BMC.
    [Arguments]  ${snmp_ip}  ${port}

    # Description of argument(s):
    # snmp_ip  SNMP manager IP.
    # port     Network port where SNMP manager is listening.

    @{ip_and_port}=  Create List  ${snmp_ip}  ${port}

    @{ip_and_port_list}=  Get List Of SNMP Manager And Port Configured On BMC

    List Should Contain Sub List  ${ip_and_port_list}  ${ip_and_port}
    ...  msg=Valid SNMP manager is not found on BMC.


Get SNMP Manager Object
    [Documentation]  Find the SNMP object for the given ip and port and return it.
    # If no object can be located, return ${EMPTY}.
    [Arguments]  ${ip}  ${port}

    # Description of argument(s):
    # ip             SNMP manager IP.
    # port           Network port where SNMP manager is listening.

    ${snmp_objs}=  Read Properties  ${SNMP_MANAGER_URI}enumerate
    FOR  ${snmp_obj}  IN   @{snmp_objs}
        ${obj}=  Set Variable  ${snmp_objs['${snmp_obj}']}
        Run Keyword If
        ...  '${obj['Address']}' == '${ip}' and '${obj['Port']}' == '${port}'
        ...    Return From Keyword  ${snmp_obj}
    END

    Return From Keyword  ${EMPTY}


Delete SNMP Manager And Object
    [Documentation]  Delete SNMP manager.
    [Arguments]  ${snmp_ip}  ${port}

    # Description of argument(s):
    # snmp_ip  SNMP manager IP.
    # port     Network port where SNMP manager is listening.

    ${snmp_obj}=  Get SNMP Manager Object  ${snmp_ip}  ${port}

    # If the given IP and port is not configured, return.
    # Otherwise, delete the IP and object.

    Run Keyword And Return If  '${snmp_obj}' == '${EMPTY}'
    ...  Pass Execution  SNMP manager to be deleted is not configured.

    OpenBMC Delete Request  ${snmp_obj}

    # Verify whether deleted SNMP is removed from BMC system.
    ${status}=  Run Keyword And Return Status  Verify SNMP Manager
    ...  ${snmp_ip}  ${port}
    Should Be Equal  ${status}  ${False}  msg=SNMP manager is not deleted.


Start SNMP Manager
    [Documentation]  Start SNMP listener on the remote SNMP manager.

    Open Connection And Log In  ${SNMP_MGR1_USERNAME}  ${SNMP_MGR1_PASSWORD}
    ...  alias=snmp_server  host=${SNMP_MGR1_IP}

    # The execution of the SNMP_TRAPD_CMD is necessary to cause SNMP to begin
    # listening to SNMP messages.
    SSHLibrary.write  ${SNMP_TRAPD_CMD} &
