*** Settings ***
Documentation       This suite will test extended Network Configuration Rest Interfaces

Resource            ../lib/rest_client.robot
Resource            ../lib/connection_client.robot
Resource            ../lib/utils.robot
Resource            ../lib/openbmc_ffdc.robot
Library             ../lib/pythonutil.py

Suite Setup         Open Connection And Log In
Suite Teardown      Close All Connections
Test Teardown       FFDC On Test Case Fail

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
    Log  ${OLD_MASK}
    set suite variable   ${OLD_IP}          ${networkInfo['data'][2]}
    set suite variable   ${OLD_GATEWAY}     ${networkInfo['data'][3]}

    Log    ${OLD_IP}
    Log    ${OLD_GATEWAY}


    ${NEW_IP}=        Get Environment Variable    NEW_BMC_IP
    ${NEW_MASK}=   Get Environment Variable    NEW_SUBNET_MASK
    ${NEW_GATEWAY}=       Get Environment Variable    NEW_GATEWAY

    ${arglist}=    Create List    eth0    ${NEW_IP}   ${NEW_MASK}   ${NEW_GATEWAY}
    ${args}=     Create Dictionary   data=@{arglist}
    run keyword and ignore error
    ...   Call Method
    ...   ${OPENBMC_BASE_URI}NetworkManager/Interface/   SetAddress4    data=${args}

    Wait For Host To Ping       ${NEW_IP}
    Set Suite Variable      ${AUTH_URI}       https://${NEW_IP}
    Log    ${AUTH_URI}

    ${networkInfo}=    Get networkInfo from the interface    eth0
    ${ipaddress}=      set variable    ${networkInfo['data'][2]}
    ${gateway}=        set variable    ${networkInfo['data'][3]}

    ${isgatewayfound}=    Set Variable If   '${gateway}'=='${NEW_GATEWAY}'  true    false
    Log   ${isgatewayfound}
    ${isIPfound}=    Set Variable if    '${ipaddress}' == '${NEW_IP}'    true   false
    should be true   '${isIPfound}' == 'true' and '${isgatewayfound}' == 'true'


Revert the last ip address change
    [Tags]   network_test
    [Documentation]   This test case sets the ip  on the interface and validates
    ...               that ip address has been set or not.
    ...               Expectation is the ip address should get added.


    ${arglist}=    Create List    eth0       ${OLD_IP}    ${OLD_MASK}   ${OLD_GATEWAY}
    ${args}=     Create Dictionary   data=@{arglist}
    run keyword and ignore error
    ...    Call Method
    ...    ${OPENBMC_BASE_URI}NetworkManager/Interface/   SetAddress4    data=${args}

    Wait For Host To Ping       ${OLD_IP}
    Set Suite Variable      ${AUTH_URI}    https://${OLD_IP}
    Log    ${AUTH_URI}


    ${networkInfo}=    Get networkInfo from the interface    eth0
    ${ipaddress}=      set variable    ${networkInfo['data'][2]}
    ${gateway}=        set variable    ${networkInfo['data'][3]}

    ${isgatewayfound}=    Set Variable If   '${gateway}'=='${OLD_GATEWAY}'  true    false
    Log   ${isgatewayfound}
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
    Log    "System is getting rebooted wait for few seconds"
    ${networkInfo}=    Get networkInfo from the interface    eth0
    ${ipaddress}=      set variable    ${networkInfo['data'][2]}
    ${gateway}=        set variable    ${networkInfo['data'][3]}

    ${isgatewayfound}=    Set Variable If   '${gateway}'=='${OLD_GATEWAY}'  true    false
    Log   ${isgatewayfound}
    ${isIPfound}=    Set Variable if    '${ipaddress}' == '${OLD_IP}'    true   false
    should be true   '${isIPfound}' == 'true' and '${isgatewayfound}' == 'true'


Set invalid Mac address     eth0     gg:hh:jj:kk:ll:mm    error
    [Tags]   network_test  Set_invalid_Mac_address
    [Template]  SetMacAddress_bad
    [Documentation]   This test case tries to set the invalid mac address
    ...               on the eth0 interface.
    ...               Expectation is that it should throw error.


Set valid Mac address     eth0     00:21:cc:73:91:dd   ok
    [Tags]   network_test  Set_valid_Mac_address
    [Template]  SetMacAddress_good
    [Documentation]   ***GOOD PATH***
    ...               This test case add the ip addresson the  interface and validates
    ...               that ip address has been added or not.
    ...               Expectation is the ip address should get added.

Revert old Mac address     eth0     ${OLD_MAC_ADDRESS}   ok
    [Tags]   network_test  Revert_old_Mac_address
    [Template]  SetMacAddress_good
    [Documentation]   ***GOOD PATH***
    ...               This test case add the ip addresson the  interface and validates
    ...               that ip address has been added or not.
    ...               Expectation is the ip address should get added.

*** Keywords ***

Get networkInfo from the interface

    [Documentation]   This keyword is used to match the given ip with the configured one.
    ...               returns true if match successfull else false
    ...               eg:- Outout of getAddress4
    ...               NewFormat:-{"data": [ 2,25,"9.3.164.147","9.3.164.129"],"message": "200 OK","status": "ok"}
    ...               OldFormat:-
    ...               {"data": [[[2,25,0,128,"9.3.164.177"],[2,8,254,128,"127.0.0.1"]],"9.3.164.129"],
    ...                "message": "200 OK", "status": "ok"}

    [Arguments]    ${intf}
    @{arglist}=    Create List   ${intf}
    ${args}=       Create Dictionary   data=@{arglist}
    ${resp}=       Call Method
    ...    ${OPENBMC_BASE_URI}NetworkManager/Interface/   GetAddress4    data=${args}
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}
    ${json}=   to json         ${resp.content}
    Log   ${json['data'][2]}
    Log   ${json['data'][3]}
    [return]    ${json}


validateEnvVariables

    ${NEW_BMC_IP}=        Get Environment Variable    NEW_BMC_IP
    ${NEW_SUBNET_MASK}=   Get Environment Variable    NEW_SUBNET_MASK
    ${NEW_GATEWAY}=       Get Environment Variable    NEW_GATEWAY


    should not be empty  ${NEW_BMC_IP}
    should not be empty  ${NEW_GATEWAY}
    should not be empty  ${NEW_SUBNET_MASK}

SetMacAddress_bad
    [Arguments]    ${intf}      ${address}    ${result}
    ${arglist}=    Create List    ${intf}    ${address}
    ${args}=       Create Dictionary   data=@{arglist}
    ${resp}=       Call Method
    ...   ${OPENBMC_BASE_URI}NetworkManager/Interface/   SetHwAddress    data=${args}
    should not be equal as strings      ${resp.status_code}     ${HTTP_OK}
    ${json}=   to json         ${resp.content}
    should be equal as strings      ${json['status']}       ${result}


SetMacAddress_good
    [Arguments]    ${intf}      ${address}   ${result}
    ${arglist}=    Create List    ${intf}    ${address}
    ${args}=       Create Dictionary   data=@{arglist}
    ${resp}=       Call Method
    ...    ${OPENBMC_BASE_URI}NetworkManager/Interface/   SetHwAddress    data=${args}
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}
    ${json}=   to json         ${resp.content}
    should be equal as strings      ${json['status']}       ${result}
    Wait For Host To Ping      ${OPENBMC_HOST}

    Wait Until Keyword Succeeds    30 sec    5 sec    Initialize OpenBMC

    @{arglist}=   Create List   ${intf}
    ${args}=     Create Dictionary   data=@{arglist}
    ${resp}=   Call Method
    ...    ${OPENBMC_BASE_URI}NetworkManager/Interface/    GetHwAddress    data=${args}
    ${json}=   to json         ${resp.content}
    should be equal as strings   ${json['data']}    ${address}
