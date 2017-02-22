*** Settings ***
Documentation      This suite will verifiy the Network Configuration Rest Interfaces
...                Details of valid interfaces can be found here...
...                https://github.com/openbmc/docs/blob/master/rest-api.md

Resource            ../lib/rest_client.robot
Resource            ../lib/connection_client.robot
Resource            ../lib/utils.robot
Resource            ../lib/openbmc_ffdc.robot
Library             ../lib/pythonutil.py

Suite Setup         Open Connection And Log In
Suite Teardown      Close All Connections
Test Teardown       FFDC On Test Case Fail

*** Variables ***

${NW_MANAGER}    ${NETWORK_MANAGER_URI}Interface

*** Test Cases ***

Get the Mac address

    [Documentation]   This test case is to get the mac address
    [Tags]   network_test
    @{arglist}=   Create List   eth0
    ${args}=     Create Dictionary   data=@{arglist}
    ${resp}=   Call Method    ${NW_MANAGER}   GetHwAddress    data=${args}
    should not be empty    ${resp.content}
    ${json}=   to json         ${resp.content}
    should be equal as strings      ${json['status']}      ok
    set suite variable   ${OLD_MAC_ADDRESS}  ${json['data']}


Get IP Address with invalid interface

    [Documentation]   This test case tries to get the ip addrees with the invalid
    ...               interface,Expectation is it should get error.
    [Tags]   network_test

    @{arglist}=   Create List   lo01
    ${args}=     Create Dictionary   data=@{arglist}
    ${resp}=    Call Method   ${NW_MANAGER}  GetAddress4    data=${args}
    should not be equal as strings      ${resp.status_code}     ${HTTP_OK}
    ${json}=   to json         ${resp.content}
    should be equal as strings      ${json['status']}       error

Get IP Address with valid interface

    [Documentation]   This test case tries to get the ip addrees with the invalid
    ...               interface,Expectation is it should get error.
    [Tags]   network_test

    @{arglist}=   Create List   eth0
    ${args}=     Create Dictionary   data=@{arglist}
    ${resp}=    Call Method   ${NW_MANAGER}  GetAddress4    data=${args}
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}
    ${json}=   to json         ${resp.content}
    should be equal as strings      ${json['status']}      ok


Set the IP address on invalid Interface            lo01     1.1.1.1        255.255.255.0     1.1.1.1     error

   [Tags]   network_test
   [Template]    AddNetworkInfo
   [Documentation]    This test case tries to set the ip addrees with the invalid
    ...               interface,Expectation is it should get error

Set invalid IP address on the valid interface      eth0     ab.cd.ef.gh    255.255.255.0     1.1.1.1     error

   [Tags]   network_test
   [Template]    AddNetworkInfo
   [Documentation]    This test case tries to set the invalid ip addrees on  the interface
    ...               Expectation is it should get error.


Set IP address with invalid subnet mask            eth0       2.2.2.2        av.ih.jk.lm       1.1.1.1     error

   [Tags]   network_test
   [Template]    AddNetworkInfo
   [Documentation]   This test case tries to set the ip addrees on  the interface
   ...               with invalid subnet mask,Expectation is it should get error.

Set empty IP address                              eth0     ${EMPTY}       255.255.255.0     1.1.1.1     error

   [Tags]   network_test
   [Template]    AddNetworkInfo
   [Documentation]   This test case tries to set the NULL ip addrees on  the interface
   ...               Expectation is it should get error.

Set empty subnet mask                             eth0       2.2.2.2        ${EMPTY}          1.1.1.1     error

   [Tags]   network_test
   [Template]    AddNetworkInfo
   [Documentation]   This test case tries to set the ip addrees on  the interface
   ...               with empty subnet mask,Expectation is it should get error.

Set empty gateway                                 eth0       2.2.2.2        255.255.255.0     ${EMPTY}    error

   [Tags]   network_test
   [Template]    AddNetworkInfo
   [Documentation]   This test case tries to set the ip addrees on  the interface
   ...               with empty gateway,Expectation is it should get error.


Get IP Address type
    [Tags]   GOOD-PATH
    [Documentation]   This test case tries to set existing ipaddress address and
    ...               later tries to verify that ip address type is set to static
    ...               due to the operation.

    ${networkInfo}=    Get networkInfo from the interface    eth0
    ${result}=  convert to integer     ${networkInfo['data'][1]}

    ${CURRENT_MASK}=    calcDottedNetmask     ${result}
    ${CURRENT_IP}=      set variable    ${networkInfo['data'][2]}
    ${CURRENT_GATEWAY}=   set variable    ${networkInfo['data'][3]}

    ${arglist}=    Create List    eth0    ${CURRENT_IP}   ${CURRENT_MASK}   ${CURRENT_GATEWAY}
    ${args}=     Create Dictionary   data=@{arglist}
    run keyword and ignore error   Call Method  ${NW_MANAGER}  SetAddress4  data=${args}

    Wait For Host To Ping       ${CURRENT_IP}

    Wait Until Keyword Succeeds    30 sec    5 sec    Initialize OpenBMC

    @{arglist}=   Create List   eth0
    ${args}=     Create Dictionary   data=@{arglist}
    ${resp}=    Call Method   ${NW_MANAGER}   GetAddressType    data=${args}
    ${json}=   to json         ${resp.content}
    Should Be Equal    ${json['data']}    STATIC
    should be equal as strings      ${json['status']}      ok

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
    ${resp}=       Call Method   ${NW_MANAGER}  GetAddress4    data=${args}
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}
    ${json}=   to json         ${resp.content}
    log to console   ${json['data'][2]}
    log to console   ${json['data'][3]}
    [Return]    ${json}

AddNetworkInfo
    [Arguments]    ${intf}      ${address}    ${mask}   ${gateway}  ${result}

    ${arglist}=    Create List    ${intf}    ${address}  ${mask}   ${gateway}
    ${args}=       Create Dictionary   data=@{arglist}
    ${resp}=       Call Method   ${NW_MANAGER}  SetAddress4    data=${args}
    should not be equal as strings      ${resp.status_code}     ${HTTP_OK}
    ${json}=   to json         ${resp.content}
    should be equal as strings      ${json['status']}       ${result}
