*** Settings ***

Documentation  Stress the system using HTX exerciser - bootme option.

# Test Parameters:
# OPENBMC_HOST        The BMC host name or IP address.
# OS_HOST             The OS host name or IP Address.
# OS_USERNAME         The OS login userid (usually root).
# OS_PASSWORD         The password for the OS login.
# HTX_DURATION        Duration of HTX run, for example, 2h, or 30m.
# HTX_LOOP            The number of times to loop HTX.


Resource        ../lib/htx_resource.robot
Resource        ../lib/os_utilities.robot
Library         ../lib/os_utils_keywords.py
Resource        ../lib/openbmc_ffdc_utils.robot
Library         ../lib/os_utilities.py
Library         DateTime

Suite Setup     Run Keyword And Ignore Error  Start SOL Console Logging
Test Setup      Test Setup Execution
Test Teardown   Test Teardown Execution

Test Tags      HTX_Softbootme

*** Variables ****

${rest_keyword}     REST

*** Test Cases ***

Soft Bootme Test
    [Documentation]  Using HTX exerciser soft boot option.
    [Tags]  Soft_Bootme_Test

    Printn
    Rprint Vars   BOOTME_PERIOD   HTX_LOOP

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

    # **********************************
    # HTX bootme_period:
    #        1 - every 20 minutes
    #        2 - every 30 minutes
    #        3 - every hour
    #        4 - every midnight
    # **********************************

    # Set a boot interval based on the given boot me period.

    ${boot_interval}=   Set Variable If
    ...  ${BOOTME_PERIOD} == 1  20m
    ...  ${BOOTME_PERIOD} == 2  30m
    ...  ${BOOTME_PERIOD} == 3  1h

    ${runtime}=  Convert Time  ${boot_interval}

    ${startTime} =    Get Current Date
    IF  '${HTX_MDT_PROFILE}' == 'mdt.bu'
        Create Default MDT Profile
    END

    Run MDT Profile

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
                IF  '${l_ping}' == '${True}'  BREAK
            END

            IF  '${l_ping}' == '${False}'  Fail  msg=OS not pinging in 20 minutes

            Wait Until Keyword Succeeds
            ...   2 min   30 sec   Verify Ping SSH And Redfish Authentication

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
        IF   ${runtime} < ${elapsedTimeSec}  BREAK
    END

    Wait Until Keyword Succeeds
    ...   15 min   30 sec   Verify Ping SSH And Redfish Authentication

    Wait Until Keyword Succeeds
    ...   2 min  60 sec   Shutdown Bootme

    # If user needs to keep the HTX running to debug on failure or post processing.
    IF  ${HTX_KEEP_RUNNING} == ${0}
        Wait Until Keyword Succeeds  2 min  60 sec   Shutdown HTX Exerciser
    END


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

    ${os_release_info}=  os_utilities.Get OS Release Info  uname
    Rprint Vars  os_release_info  fmt=1

    # Shutdown if HTX is running.
    ${status}=  Is HTX Running
    IF  '${status}' == 'True'
        Wait Until Keyword Succeeds  2 min  60 sec   Shutdown HTX Exerciser
    END


Test Teardown Execution
    [Documentation]  Do the post-test teardown.

    # Keep HTX running if user set HTX_KEEP_RUNNING to 1.
    IF  '${TEST_STATUS}' == 'FAIL' and ${HTX_KEEP_RUNNING} == ${0}
        Wait Until Keyword Succeeds  2 min  60 sec   Shutdown HTX Exerciser
    END

    ${keyword_buf}=  Catenate  Stop SOL Console Logging
    ...  \ targ_file_path=${EXECDIR}${/}logs${/}SOL.log
    Run Keyword And Ignore Error   ${keyword_buf}

    FFDC On Test Case Fail

    Close All Connections
