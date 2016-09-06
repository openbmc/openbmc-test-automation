*** Settings ***
Documentation		This suite will test extended Network Configuration Rest Interfaces

Resource            ../lib/rest_client.robot
Resource            ../lib/connection_client.robot
Resource            ../lib/utils.robot
Resource            ../lib/openbmc_ffdc.robot
Library             ../lib/pythonutil.py

Suite Setup         Open Connection And Log In
Suite Teardown      Close All Connections
Test Teardown       Log FFDC

*** Test Cases ***

Set IP address on valid Interface
    [Tags]   network_test
    [Documentation]   This test case sets the ip on the interface and validates
    ...               that ip address has been set or not.
    ...               Expectation is the ip address should get added.

    validateEnvVariables


    ${networkInfo}=    Get networkInfo from the interface    eth0
    ${result}=  convert to integer     ${networkInfo['data'][1]}

    ${MASK}=    calcDottedNetmask     ${result}
    set suite variable   ${OLD_MASK}   ${MASK}
    log to console  ${OLD_MASK}
    set suite variable   ${OLD_IP}          ${networkInfo['data'][2]}
    set suite variable   ${OLD_GATEWAY}     ${networkInfo['data'][3]}

    log to console    ${OLD_IP}
    log to console    ${OLD_GATEWAY}


    ${NEW_IP}=        Get Environment Variable    NEW_BMC_IP
    ${NEW_MASK}=   Get Environment Variable    NEW_SUBNET_MASK
    ${NEW_GATEWAY}=       Get Environment Variable    NEW_GATEWAY

    ${arglist}=    Create List    eth0    ${NEW_IP}   ${NEW_MASK}   ${NEW_GATEWAY}
    ${args}=     Create Dictionary   data=@{arglist}
    run keyword and ignore error    Call Method    /org/openbmc/NetworkManager/Interface/   SetAddress4    data=${args}

    Wait For Host To Ping       ${NEW_IP}
    Set Suite Variable      ${AUTH_URI}       https://${NEW_IP}
    log to console    ${AUTH_URI}

    ${networkInfo}=    Get networkInfo from the interface    eth0
    ${ipaddress}=      set variable    ${networkInfo['data'][2]}
    ${gateway}=        set variable    ${networkInfo['data'][3]}

    ${isgatewayfound} =    Set Variable If   '${gateway}'=='${NEW_GATEWAY}'  true    false
    log to console   ${isgatewayfound}
    ${isIPfound}=    Set Variable if    '${ipaddress}' == '${NEW_IP}'    true   false
    should be true   '${isIPfound}' == 'true' and '${isgatewayfound}' == 'true'


Revert the last ip address change
    [Tags]   network_test
    [Documentation]   This test case sets the ip  on the interface and validates
    ...               that ip address has been set or not.
    ...               Expectation is the ip address should get added.


    ${arglist}=    Create List    eth0       ${OLD_IP}    ${OLD_MASK}   ${OLD_GATEWAY}
    ${args}=     Create Dictionary   data=@{arglist}
    run keyword and ignore error    Call Method    /org/openbmc/NetworkManager/Interface/   SetAddress4    data=${args}

    Wait For Host To Ping       ${OLD_IP}
    Set Suite Variable      ${AUTH_URI}    https://${OLD_IP}
    log to console    ${AUTH_URI}


    ${networkInfo}=    Get networkInfo from the interface    eth0
    ${ipaddress}=      set variable    ${networkInfo['data'][2]}
    ${gateway}=        set variable    ${networkInfo['data'][3]}

    ${isgatewayfound} =    Set Variable If   '${gateway}'=='${OLD_GATEWAY}'  true    false
    log to console   ${isgatewayfound}
    ${isIPfound}=    Set Variable if    '${ipaddress}' == '${OLD_IP}'    true   false
    should be true   '${isIPfound}' == 'true' and '${isgatewayfound}' == 'true'


Persistency check for ip address
    [Tags]   reboot_test
    [Documentation]   we reboot the service processor and after reboot
    ...               will request for the ip address to check the persistency
    ...               of the ip address.
    ...               Expectation is the ip address should persist.

    Open Connection And Log In
    Execute Command    reboot
    log to console    "System is getting rebooted wait for few seconds"
    ${networkInfo}=    Get networkInfo from the interface    eth0
    ${ipaddress}=      set variable    ${networkInfo['data'][2]}
    ${gateway}=        set variable    ${networkInfo['data'][3]}

    ${isgatewayfound} =    Set Variable If   '${gateway}'=='${OLD_GATEWAY}'  true    false
    log to console   ${isgatewayfound}
    ${isIPfound}=    Set Variable if    '${ipaddress}' == '${OLD_IP}'    true   false
    should be true   '${isIPfound}' == 'true' and '${isgatewayfound}' == 'true'


***keywords***

Get networkInfo from the interface

    [Documentation]   This keyword is used to match the given ip with the configured one.
    ...               returns true if match successfull else false
    ...               eg:- Outout of getAddress4
    ...               NewFormat:-{"data": [ 2,25,"9.3.164.147","9.3.164.129"],"message": "200 OK","status": "ok"}
    ...               OldFormat:-
    ...               {"data": [[[2,25,0,128,"9.3.164.177"],[2,8,254,128,"127.0.0.1"]],"9.3.164.129"],
    ...                "message": "200 OK", "status": "ok"}

    [arguments]    ${intf}
    @{arglist}=    Create List   ${intf}
    ${args}=       Create Dictionary   data=@{arglist}
    ${resp}=       Call Method    /org/openbmc/NetworkManager/Interface/   GetAddress4    data=${args}
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}
    ${json} =   to json         ${resp.content}
    log to console   ${json['data'][2]}
    log to console   ${json['data'][3]}
    [return]    ${json}


validateEnvVariables

    ${NEW_BMC_IP}=        Get Environment Variable    NEW_BMC_IP
    ${NEW_SUBNET_MASK}=   Get Environment Variable    NEW_SUBNET_MASK
    ${NEW_GATEWAY}=       Get Environment Variable    NEW_GATEWAY


    should not be empty  ${NEW_BMC_IP}
    should not be empty  ${NEW_GATEWAY}
    should not be empty  ${NEW_SUBNET_MASK}
