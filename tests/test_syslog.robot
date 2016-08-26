*** Settings ***

Documentation       This suite is for testing syslog function of Open BMC.

Resource            ../lib/rest_client.robot
Resource            ../lib/utils.robot
Resource            ../lib/connection_client.robot

Suite Setup         Open Connection And Log In
Suite Teardown      Close All Connections
Test Teardown       Log FFDC


*** Variables ***
${INVALID_SYSLOG_IP_ADDRESS}      a.ab.c.d
${INVALID_SYSLOG_PORT}            abc
${SYSTEM_SHUTDOWN_TIME}           1min
${WAIT_FOR_SERVICES_UP}           3min

*** Test Cases ***

Get all Syslog settings
    [Documentation]     ***GOOD PATH***
    ...                 This testcase is to get all syslog settings from
    ...                 open bmc system.\n

    ${ip_address} =    Read Attribute    /org/openbmc/LogManager/rsyslog   ipaddr
    Should Not Be Empty     ${ip_address}

    ${port} =    Read Attribute    /org/openbmc/LogManager/rsyslog   port
    Should Not Be Empty     ${port}

    ${status} =    Read Attribute    /org/openbmc/LogManager/rsyslog   status
    Should Not Be Empty     ${status}

Enable syslog with port number and IP address
    [Documentation]     ***GOOD PATH***
    ...                 This testcase is to enable syslog with both ip address
    ...                 and port number of remote system.\n

    ${resp} =    Enable Syslog Setting    ${SYSLOG_IP_ADDRESS}    ${SYSLOG_PORT}
    Should Be Equal    ${resp}    ok
    ${ip}=   Read Attribute   /org/openbmc/LogManager/rsyslog   ipaddr
    Should Be Equal    ${ip}    ${SYSLOG_IP_ADDRESS}
    ${port}=   Read Attribute   /org/openbmc/LogManager/rsyslog   port
    Should Be Equal    ${port}    ${SYSLOG_PORT}

Enable syslog without IP address and port number
    [Documentation]     ***GOOD PATH***
    ...                 This testcase is to enable syslog without changing ip address
    ...                 and port number.\n

    ${resp} =    Enable Syslog Setting    ${EMPTY}    ${EMPTY}
    Should Be Equal    ${resp}    ok
    ${status}=   Read Attribute   /org/openbmc/LogManager/rsyslog   status
    Should Be Equal    ${status}    Enabled

Enable syslog with only IP address
    [Documentation]     ***GOOD PATH***
    ...                 This testcase is to enable syslog with only ip address.\n

    ${resp} =    Enable Syslog Setting    ${SYSLOG_IP_ADDRESS}    ${EMPTY}
    Should Be Equal    ${resp}    ok
    ${ip}=   Read Attribute   /org/openbmc/LogManager/rsyslog   ipaddr
    Should Be Equal    ${ip}    ${SYSLOG_IP_ADDRESS}
    ${status}=   Read Attribute   /org/openbmc/LogManager/rsyslog   status
    Should Be Equal    ${status}    Enabled

Enable Syslog with only port number
    [Documentation]     ***GOOD PATH***
    ...                 This testcase is to enable syslog with only port number.\n

    ${status}=   Read Attribute   /org/openbmc/LogManager/rsyslog   status
    Should Be Equal    ${status}    Enabled
    ${resp} =    Enable Syslog Setting    ${EMPTY}    ${SYSLOG_PORT}
    Should Be Equal    ${resp}    ok
    ${port}=   Read Attribute   /org/openbmc/LogManager/rsyslog   port
    Should Be Equal    ${port}    ${SYSLOG_PORT}
    ${status}=   Read Attribute   /org/openbmc/LogManager/rsyslog   status
    Should Be Equal    ${status}    Enabled

Disable Syslog
    [Documentation]     ***GOOD PATH***
    ...                 This testcase is to verify disabling syslog.\n

    ${resp} =    Disable Syslog Setting    ${EMPTY}
    Should Be Equal    ${resp}    ok
    ${status}=   Read Attribute   /org/openbmc/LogManager/rsyslog   status
    Should Be Equal    Disable    ${status}

Enable invalid ip for Syslog remote server
    [Documentation]     ***BAD PATH***
    ...                 This testcase is to verify error while enabling syslog with
    ...                 invalid ip address.\n

    ${resp} =    Enable Syslog Setting    ${INVALID_SYSLOG_IP_ADDRESS}    ${SYSLOG_PORT}
    Should Be Equal    ${resp}    error

Enable invalid port for Syslog remote server
    [Documentation]     ***BAD PATH***
    ...                 This testcase is to verify error while enabling syslog with
    ...                 invalid port number.\n

    ${resp} =    Enable Syslog Setting    ${SYSLOG_IP_ADDRESS}    ${INVALID_SYSLOG_PORT}
    Should Be Equal    ${resp}    error


Persistency check for syslog setting
    [Documentation]   This test case is to verify that syslog setting does not change
    ...               after service processor reboot.
    [Tags]  bmcreboot

    ${old_ip}=   Read Attribute   /org/openbmc/LogManager/rsyslog   ipaddr
    ${old_port}=   Read Attribute   /org/openbmc/LogManager/rsyslog   port
    ${old_status} =    Read Attribute    /org/openbmc/LogManager/rsyslog   status
    
    ${output}=      Execute Command    /sbin/reboot
    Sleep   ${SYSTEM_SHUTDOWN_TIME}
    Wait For Host To Ping   ${OPENBMC_HOST}
    Sleep   ${WAIT_FOR_SERVICES_UP}

    ${ip_address} =    Read Attribute    /org/openbmc/LogManager/rsyslog   ipaddr
    ${port} =    Read Attribute    /org/openbmc/LogManager/rsyslog   port
    ${status} =    Read Attribute    /org/openbmc/LogManager/rsyslog   status

    Should Be Equal    ${old_ip}    ${ip_address}
    Should Be Equal    ${old_port}    ${port}
    Should Be Equal    ${old_status}    ${status}

*** Keywords ***

Enable Syslog Setting
    [Arguments]    ${ipaddr}    ${port}
    ${MYDICT}=  create Dictionary   ipaddr=${ipaddr}  port=${port}
    @{rsyslog} =   Create List     ${MYDICT}
    ${data} =   create dictionary   data=@{rsyslog}
    ${resp} =   openbmc post request    /org/openbmc/LogManager/rsyslog/action/Enable     data=${data}
    ${jsondata} =    to json    ${resp.content}
    [return]    ${jsondata['status']}

Disable Syslog Setting
    [Arguments]    ${args}
    @{setting_list} =   Create List     ${args}
    ${data} =   create dictionary   data=@{setting_list}
    ${resp} =   OpenBMC Post Request    /org/openbmc/LogManager/rsyslog/action/Disable      data=${data}
    ${jsondata} =    to json    ${resp.content}
    [return]    ${jsondata['status']}
