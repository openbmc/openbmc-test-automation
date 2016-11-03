*** Settings ***
Documentation  Contains all of the keywords that do various reboots.

Resource    ../resource.txt
Resource    ../utils.robot
Resource    ../connection_client.robot
Library     DateTime

*** Keywords ***
BMC Reboot
    [Documentation]  Gets the uptime of the BMC, then reboots the BMC. If an OS_HOST
    ...  is given, will also attempt to get the uptime of the OS Host and verify that
    ...  the host stayed active during the reboot.

    &{bmc_connection_args}=  Create Dictionary  alias=bmc_connection
    ${OS_exists}=  Set Variable If  '${OS_HOST}' != '${EMPTY}'  ${True}
    ...                             '${OS_HOST}' == '${EMPTY}'  ${False}

    &{os_connection_args}=  Run Keyword If  ${OS_exists} == ${True}
    ...  Create Dictionary  host=${OS_HOST}  alias=os_connection

    Open Connection and Log In  &{bmc_connection_args}

    ${bmc_start_uptime}=  Get Uptime In Seconds

    ${conn_rc}=  Run Keyword and Return Status  Run Keyword If  ${OS_exists} == ${True}
    ...  Open Connection and Log In  ${OS_USERNAME}  ${OS_PASSWORD}  &{os_connection_args}

    ${OS_exists}=  Set Variable If  ${conn_rc} == False  ${False}

    ${ping_rc}=  Run Keyword and Return Status  Ping Host  ${OS_HOST}
    ${OS_exists}=  Set Variable If  ${ping_rc} == ${False}  ${False}

    ${os_start_uptime}=  Run Keyword If  ${OS_exists} == ${True}   Get Uptime In Seconds

    Validate Connection  bmc_connection

    Reboot BMC
    Sleep  1 min
    Wait For Host to Ping  ${OPENBMC_HOST}

    Close All Connections
    Open Connection and Log In  &{bmc_connection_args}

    ${bmc_end_uptime}=  Get Uptime In Seconds
    Should Be True  ${bmc_end_uptime} < ${bmc_start_uptime}

    Run Keyword If  ${OS_exists} == ${True}
    ...  Open Connection and Log In  ${OS_USERNAME}  ${OS_PASSWORD}  &{os_connection_args}

    ${os_end_uptime}=  Run Keyword If  ${OS_exists} == ${True}  Get Uptime In Seconds

    Run Keyword If  ${OS_exists} == ${True}
    ...  Should Be True  ${os_end_uptime} > ${os_start_uptime}

    Close All Connections

Get Uptime In Seconds
    ${uptime_string}  ${stderr}  ${rc}=  Execute Command  uptime
    ...  return_stderr=True  return_rc=True

    Should Be Empty  ${stderr}
    Should Be Equal  ${rc}  ${0}

    ${machine_time}  ${string_end}=  Split String  ${uptime_string}  up  1
    ${uptime}  ${info}=  Split String  ${string_end}  ,  1
    ${uptime}=  Strip String  ${uptime}  

    ${uptime}=  Convert Time  ${uptime}

    [return]  ${uptime}

Reboot BMC
    Start Command  /sbin/reboot
