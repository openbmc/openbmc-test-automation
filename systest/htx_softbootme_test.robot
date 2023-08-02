*** Settings ***

Documentation  Stress the system using HTX exerciser - bootme option.

# Test Parameters:
# OPENBMC_HOST        The BMC host name or IP address.
# OS_HOST             The OS host name or IP Address.
# OS_USERNAME         The OS login userid (usually root).
# OS_PASSWORD         The password for the OS login.
# HTX_DURATION        Duration of HTX run, for example, 2h, or 30m.
# HTX_LOOP            The number of times to loop HTX.


Resource        ../syslib/resource.robot
Resource        ../syslib/utils_os.robot
Library         ../syslib/utils_keywords.py
Resource        ../lib/openbmc_ffdc_utils.robot
Library         ../syslib/utils_os.py
Library         DateTime

Suite Setup     Start SOL Console Logging
Test Setup      Test Setup Execution
Test Teardown   Test Teardown Execution

*** Variables ****

${rest_keyword}     REST

*** Test Cases ***

Soft Bootme Test
    [Documentation]  Using HTX exerciser soft boot option.
    [Tags]  Soft_Bootme_Test

    Printn
    Rprint Vars  HTX_DURATION  HTX_LOOP

    # Set up the (soft) bootme iteration (loop) counter.
    Set Suite Variable  ${iteration}  ${0}  children=true

    # Run test
    Repeat Keyword  ${HTX_LOOP} times  Run HTX Soft Bootme Exerciser


*** Keywords ***


Run HTX Soft Bootme Exerciser
    [Documentation]  Run HTX Soft Bootme Exerciser.
    # Test Flow:
    # - Power on.
    # - Create HTX mdt profile.
    # - Run HTX exerciser.
    # - Soft bootme (OS Reboot).
    # - Check HTX status for errors.

    ${runtime}=   Convert Time  ${HTX_DURATION}

    ${startTime} =    Get Current Date
    Run Keyword If  '${HTX_MDT_PROFILE}' == 'mdt.bu'
    ...  Create Default MDT Profile

    Run MDT Profile

    # **********************************
    # HTX bootme_period:
    #        1 - every 20 minutes
    #        2 - every 30 minutes
    #        3 - every hour
    #        4 - every midnight
    # **********************************
    Run Soft Bootme  ${BOOTME_PERIOD}

    FOR    ${index}    IN RANGE    999999
        ${l_ping}=
        ...   Run Keyword And Return Status   Ping Host  ${OS_HOST}

        IF   '${l_ping}' == '${False}'
            Log to console   ("OS Host is rebooting")
            # Wait for OS (re) Boot - Max 20 minutes
            FOR   ${waitindex}   IN RANGE   40
                Run Key U  Sleep \ 30s
                ${l_ping}=
                ...   Run Keyword And Return Status   Ping Host  ${OS_HOST}
                Exit For Loop If    '${l_ping}' == '${True}'
            END

            Run Keyword If  '${l_ping}' == '${False}'  Fail  msg=OS not pinging in 20 minutes

            Wait Until Keyword Succeeds
            ...   1 min   30 sec   Verify Ping SSH And Redfish Authentication

            Wait Until Keyword Succeeds
            ...   3x  60 sec  OS Execute Command  uptime
            Wait Until Keyword Succeeds
            ...   1 min   30 sec   Check HTX Run Status

            Set Suite Variable  ${iteration}  ${iteration + 1}
            ${loop_count}=  Catenate  Completed reboot number: ${iteration}

            Printn
            Rprint Vars  loop_count
        END

        ${currentTime} =    Get Current Date
        ${elapsedTimeSec} =
        ...   Subtract Date From Date
        ...   ${currentTime}   ${startTime}   result_format=number   exclude_millis=True
        Exit For Loop If   ${runtime} < ${elapsedTimeSec}
    END

    Wait Until Keyword Succeeds
    ...   15 min   30 sec   Verify Ping SSH And Redfish Authentication

    Shutdown Bootme

    # If user needs to keep the HTX running to debug on failure or post processing.
    Run Keyword If  ${HTX_KEEP_RUNNING} == ${0}  Shutdown HTX Exerciser


Test Setup Execution
    [Documentation]  Do the initial test setup.

    ${bmc_version}  ${stderr}  ${rc}=  BMC Execute Command
    ...  cat /etc/os-release
    Printn
    Rprint Vars  bmc_versionhtxcmdline -bootme

    ${fw_version}=  Get BMC Version
    Rprint Vars  fw_version

    ${is_redfish}=  Run Keyword And Return Status  Redfish.Login
    ${rest_keyword}=  Set Variable If  ${is_redfish}  Redfish  REST
    Rprint Vars  rest_keyword
    Set Suite Variable  ${rest_keyword}  children=true

    Run Keyword  ${rest_keyword} Power On  stack_mode=skip

    Run Key U  Sleep \ 15s
    Run Keyword And Ignore Error  Delete All Error Logs
    Run Keyword And Ignore Error  Redfish Purge Event Log
    Tool Exist  htxcmdline

    ${os_release_info}=  utils_os.Get OS Release Info  uname
    Rprint Vars  os_release_info  fmt=1

    # Shutdown if HTX is running.
    ${status}=  Is HTX Running
    Run Keyword If  '${status}' == 'True'
    ...  Shutdown HTX Exerciser


Test Teardown Execution
    [Documentation]  Do the post-test teardown.

    # Keep HTX running if user set HTX_KEEP_RUNNING to 1.
    Run Keyword If
    ...  '${TEST_STATUS}' == 'FAIL' and ${HTX_KEEP_RUNNING} == ${0}
    ...  Shutdown HTX Exerciser

    ${keyword_buf}=  Catenate  Stop SOL Console Logging
    ...  \ targ_file_path=${EXECDIR}${/}logs${/}SOL.log
    Run Key  ${keyword_buf}

    Close All Connections
