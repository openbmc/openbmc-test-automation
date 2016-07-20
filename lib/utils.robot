*** Settings ***
Resource                ../lib/resource.txt
Resource                ../lib/rest_client.robot

Library                 OperatingSystem

*** Variables ***
${SYSTEM_SHUTDOWN_TIME}       ${5}

*** Keywords ***

Wait For Host To Ping
    [Arguments]     ${host}
    Wait Until Keyword Succeeds     ${OPENBMC_REBOOT_TIMEOUT}min    5 sec   Ping Host   ${host}

Ping Host
    [Arguments]     ${host}
    ${RC}   ${output} =     Run and return RC and Output    ping -c 4 ${host}
    Log     RC: ${RC}\nOutput:\n${output}
    Should be equal     ${RC}   ${0}

Get Boot Progress
    ${state} =     Read Attribute    /org/openbmc/sensors/host/BootProgress    value
    [return]  ${state}

Is Power On
    ${state} =    Get Boot Progress
    Should be equal   ${state}     FW Progress, Starting OS

Is Power Off
    ${state} =    Get Boot Progress
    Should be equal   ${state}     Off

Power On Host
    @{arglist}=   Create List
    ${args}=     Create Dictionary    data=@{arglist}
    ${resp}=   Call Method    /org/openbmc/control/chassis0/    powerOn    data=${args}
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}
    Wait Until Keyword Succeeds	  3 min    	10 sec    Is Power On

Power Off Host
    @{arglist}=   Create List
    ${args}=     Create Dictionary    data=@{arglist}
    ${resp}=   Call Method    /org/openbmc/control/chassis0/    powerOff   data=${args}
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}
    Wait Until Keyword Succeeds	  1 min    	10 sec    Is Power Off

Trigger Warm Reset
    log to console    "Triggering warm reset"
    ${data} =   create dictionary   data=@{EMPTY}
    ${resp} =   openbmc post request    /org/openbmc/control/bmc0/action/warmReset     data=${data}
    Should Be Equal As Strings      ${resp.status_code}     ${HTTP_OK}
    Sleep   ${SYSTEM_SHUTDOWN_TIME}min
    Wait For Host To Ping   ${OPENBMC_HOST}

Check OS
    [Documentation]  Checks that the host OS is up by running an SSH command.

    [Arguments]  ${os_host}=${OS_HOST}  ${os_username}=${OS_USERNAME}
    ...          ${os_password}=${OS_PASSWORD}
    [Teardown]  Close Connection

    # os_host           The DNS name/IP of the OS host associated with our BMC.
    # os_username       The username to be used to sign on to the OS host.
    # os_password       The password to be used to sign on to the OS host.

    Open connection  ${os_host}
    Login  ${os_username}  ${os_password}

    ${output}  ${stderr}  ${rc}=  Execute Command  uptime  return_stderr=True
    ...        return_rc=True

    # If the return code returned by "Execute Command" is non-zero, this keyword
    # will fail.
    Should Be Equal  ${rc}      ${0}
    # We will likewise fail if there is any stderr data.
    Should Be Empty  ${stderr}

Wait for OS
    [Documentation]  Waits for the host OS to come up via calls to "Check OS".
    [Arguments]  ${os_host}=${OS_HOST}  ${os_username}=${OS_USERNAME}
    ...          ${os_password}=${OS_PASSWORD}  ${timeout}=${OS_WAIT_TIMEOUT}

    # os_host           The DNS name or IP of the OS host associated with our
    #                   BMC.
    # os_username       The username to be used to sign on to the OS host.
    # os_password       The password to be used to sign on to the OS host.
    # timeout           The timeout in seconds indicating how long you're
    #                   willing to wait for the OS to respond.

    # The interval to be used between calls to "Check OS".
    ${interval}=  Set Variable  5

    Wait Until Keyword Succeeds  ${timeout} sec  ${interval}  Check OS
    ...                          ${os_host}  ${os_username}  ${os_password}
