*** Settings ***
Documentation  Test for HW CI.

Library             DateTime

Resource            ../../lib/utils.robot
Resource            ../../lib/ipmi_client.robot
Resource            ../../lib/boot_utils.robot
Resource            ../../lib/openbmc_ffdc.robot
Resource            ../../lib/bmc_redfish_resource.robot

Test Teardown       FFDC On Test Case Fail

*** Variables ***

# Error strings to check from journald.
${ERROR_REGEX}     SEGV|core-dump|FAILURE
${STANDBY_REGEX}   Startup finished in

# 3 minutes standby boot time.
${startup_time_threshold}  180

*** Test Cases ***

Verify Application Services Running At Standby
    [Documentation]  Check if there are services that have not completed.
    [Tags]  Verify_Application_Services_Running_At_Standby

    # Application services running on the BMC are not tightly coupled.
    # At standby, there shouldn't be any pending job waiting to complete.
    # Examples:
    # Failure o/p:
    # root@witherspoon:~# systemctl list-jobs --no-pager | cat
    #    JOB UNIT                                     TYPE  STATE
    # 35151 xyz.openbmc_project.ObjectMapper.service start running
    # 1 jobs listed.
    #
    # Success o/p:
    # root@witherspoon:~# systemctl list-jobs --no-pager | cat
    # No jobs running.

    Redfish Hard Power Off
    ${stdout}  ${stderr}  ${rc}=  BMC Execute Command
    ...  systemctl list-jobs --no-pager | cat
    Should Be Equal As Strings  ${stdout}  No jobs running.


Check For Application Failures
    [Documentation]  Parse the journal log and check for failures.
    [Tags]  Check_For_Application_Failures

    Check For Regex In Journald  ${ERROR_REGEX}  error_check=${0}  boot=-b


Verify Uptime Average Against Threshold
    [Documentation]  Compare BMC average boot time to a constant threshold.
    [Tags]  Verify_Uptime_Average_Against_Threshold

    Redfish OBMC Reboot (off)

    Wait Until Keyword Succeeds
    ...  1 min  30 sec  Check BMC Uptime Journald


Test SSH And IPMI Connections
    [Documentation]  Try SSH and IPMI commands to verify each connection.
    [Tags]  Test_SSH_And_IPMI_Connections

    BMC Execute Command  true
    Run IPMI Standard Command  chassis status


*** Keywords ***

Check BMC Uptime Journald
    [Documentation]  Check BMC journald uptime entry.

    # Example output:
    # Startup finished in 10.074s (kernel) + 2min 23.506s (userspace) = 2min 33.581s.
    ${startup_time}  ${stderr}  ${rc}=  BMC Execute Command
    ...  journalctl --no-pager | egrep '${STANDBY_REGEX}' | tail -1
    Should Not Be Empty  ${startup_time}

    # Example time conversion:
    # Get the "2min 33.581s" string total time taken to reach standby.
    # Convert time "2min 33.581s" to unit 153.581.
    ${startup_time}=  Convert Time  ${startup_time.split("= ",1)[1].strip(".")}

    Should Be True  ${startup_time} < ${startup_time_threshold}
    ...  msg=${startup_time} greater than threshold value of ${startup_time_threshold}.
