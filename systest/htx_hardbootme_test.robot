*** Settings ***

Documentation  Stress the system using HTX exerciser.

# Test Parameters:
# OPENBMC_HOST        The BMC host name or IP address.
# OS_HOST             The OS host name or IP Address.
# OS_USERNAME         The OS login userid (usually root).
# OS_PASSWORD         The password for the OS login.
# HTX_DURATION        Duration of HTX run, for example, 2h, or 30m.
# HTX_LOOP            The number of times to loop HTX.
# HTX_INTERVAL        The time delay between consecutive checks of HTX
#                     status, for example, 15m.
#                     In summary: Run HTX for $HTX_DURATION, looping
#                     $HTX_LOOP times checking for errors every
#                     $HTX_INTERVAL.  Then allow extra time for OS
#                     Boot, HTX startup, shutdown.
# HTX_KEEP_RUNNING    If set to 1, this indicates that the HTX is to
#                     continue running after an error was found.
# CHECK_INVENTORY     If set to 0 or False, OS inventory checking before
#                     and after each HTX run will be disabled.  This
#                     parameter is optional.  The default value is True.
# PREV_INV_FILE_PATH  The file path and name of an initial previous
#                     inventory snapshot file in JSON format.  Inventory
#                     snapshots taken before and after each HTX run will
#                     be compared to this file.
#                     This parameter is optional.  If not specified an
#                     initial inventory snapshot will be taken before
#                     HTX startup.
# INV_IGNORE_LIST     A comma-delimited list of strings that
#                     indicate what to ignore if there are inventory
#                     differences, (e.g., processor "size").
#                     If differences are found during inventory checking
#                     and those items are in this list, the
#                     differences will be ignored.  This parameter is
#                     optional.  If not specified the default value is
#                     "size".

Resource        ../lib/os_utilities.robot
Resource        ../lib/openbmc_ffdc_utils.robot
Resource        ../lib/logging_utils.robot
Resource        ../lib/code_update_utils.robot
Resource        ../lib/esel_utils.robot
Resource        ../lib/htx_resource.robot
Library         ../lib/os_utils_keywords.py
Library         ../lib/utils_files.py
Library         ../lib/logging_utils.py
Library         ../lib/os_utilities.py

Suite Setup     Run Keyword And Ignore Error  Start SOL Console Logging
Test Setup      Test Setup Execution
Test Teardown   Test Teardown Execution

Test Tags      HTX_Hardbootme

*** Variables ****

${stack_mode}                skip
${json_initial_file_path}    ${EXECDIR}/os_inventory_initial.json
${json_final_file_path}      ${EXECDIR}/os_inventory_final.json
${json_diff_file_path}       ${EXECDIR}/os_inventory_diff.json
${CHECK_INVENTORY}           True
${INV_IGNORE_LIST}           size
${PREV_INV_FILE_PATH}        NONE

${rest_keyword}              REST

# Error log Severities to ignore when checking Error Logs.
@{ESEL_IGNORE_LIST}
...  xyz.openbmc_project.Logging.Entry.Level.Informational



*** Test Cases ***

Hard Bootme Test
    [Documentation]  Stress the system using HTX exerciser.
    [Tags]  Hard_Bootme_Test

    Printn
    Rprint Vars  HTX_DURATION  HTX_LOOP  HTX_INTERVAL  CHECK_INVENTORY
    ...  INV_IGNORE_LIST  PREV_INV_FILE_PATH

    IF  '${PREV_INV_FILE_PATH}' != 'NONE'
        OperatingSystem.File Should Exist  ${PREV_INV_FILE_PATH}
    END

    Set Suite Variable  ${PREV_INV_FILE_PATH}  children=true
    Set Suite Variable  ${INV_IGNORE_LIST}  children=true

    # Set up the iteration (loop) counter.
    Set Suite Variable  ${iteration}  ${0}  children=true

    # Estimate the time required for a single iteration loop.
    # HTX_DURATION + 10 minutes for OS boot, HTX startup, shutdown.
    ${loop_body_seconds}=  Add Time To Time  ${HTX_DURATION}  10m
    Set Suite Variable  ${loop_body_seconds}  children=true
    # And save it in printable (compact) format.
    ${estimated_loop_time}=  Convert Time
    ...  ${loop_body_seconds}  result_format=compact
    Set Suite Variable  ${estimated_loop_time}  children=true

    # Estimated time remaining =  loop_body_seconds * HTX_LOOP + 5m
    ${est_seconds_left}=  Evaluate  ${loop_body_seconds}*${HTX_LOOP}+(5*60)
    Set Suite Variable  ${est_seconds_left}  children=true

    Repeat Keyword  ${HTX_LOOP} times  Run HTX Exerciser


*** Keywords ***


Run HTX Exerciser
    [Documentation]  Run HTX exerciser.
    # Test Flow:
    # - Power on.
    # - Establish SSH connection session.
    # - Do inventory collection, compare with
    #   previous inventory run if applicable.
    # - Create HTX mdt profile.
    # - Run HTX exerciser.
    # - Check HTX status for errors.
    # - Do inventory collection, compare with
    #   previous inventory run.
    # - Power off.

    Set Suite Variable  ${iteration}  ${iteration + 1}
    ${loop_count}=  Catenate  Starting iteration: ${iteration}
    ${estimated_time_remaining}=  Convert Time
    ...  ${est_seconds_left}  result_format=compact
    Printn
    Rprint Vars  loop_count  estimated_loop_time   estimated_time_remaining

    Run Keyword  ${rest_keyword} Power On  stack_mode=skip
    Run Key U  Sleep \ 15s

    # Post Power off and on, the OS SSH session needs to be established.
    Login To OS

    IF  '${CHECK_INVENTORY}' == 'True'
        Do Inventory And Compare  ${json_initial_file_path}  ${PREV_INV_FILE_PATH}
    END

    IF  '${HTX_MDT_PROFILE}' == 'mdt.bu'  Create Default MDT Profile

    Run MDT Profile

    Loop HTX Health Check

    Shutdown HTX Exerciser

    IF  '${CHECK_INVENTORY}' == 'True'
        Do Inventory And Compare  ${json_final_file_path}  ${PREV_INV_FILE_PATH}
    END

    Run Keyword  ${rest_keyword} Power Off

    # Close all SSH and REST active sessions.
    Close All Connections
    Flush REST Sessions

    Print Timen  HTX Test ran for: ${HTX_DURATION}

    ${loop_count}=  Catenate  Ending iteration: ${iteration}

    ${est_seconds_left}=  Evaluate  ${est_seconds_left}-${loop_body_seconds}
    Set Suite Variable  ${est_seconds_left}  children=true
    ${estimated_time_remaining}=  Convert Time
    ...  ${est_seconds_left}  result_format=compact

    Rprint Vars  loop_count  estimated_time_remaining


Do Inventory And Compare
    [Documentation]  Do inventory and compare.
    [Arguments]  ${inventory_file_path}  ${PREV_INV_FILE_PATH}
    # Description of argument(s):
    # inventory_file_path  The file to receive the inventory snapshot.
    # PREV_INV_FILE_PATH   The previous inventory to compare with.

    Create JSON Inventory File  ${inventory_file_path}
    IF  '${PREV_INV_FILE_PATH}' != 'NONE'
        Compare Json Inventory Files  ${inventory_file_path}  ${PREV_INV_FILE_PATH}
    END
    ${PREV_INV_FILE_PATH}=   Set Variable  ${inventory_file_path}
    Set Suite Variable  ${PREV_INV_FILE_PATH}  children=true


Compare Json Inventory Files
    [Documentation]  Compare JSON inventory files.
    [Arguments]  ${file1}  ${file2}
    # Description of argument(s):
    # file1   A file that has an inventory snapshot in JSON format.
    # file2   A file that has an inventory snapshot, to compare with file1.

    ${diff_rc}=  File_Diff  ${file1}
    ...  ${file2}  ${json_diff_file_path}  ${INV_IGNORE_LIST}
    IF  '${diff_rc}' != '${0}'
        Report Inventory Mismatch  ${diff_rc}  ${json_diff_file_path}
    ELSE
        Print Timen  Inventoy check: No differences found.
    END

Report Inventory Mismatch
    [Documentation]  Report inventory mismatch.
    [Arguments]  ${diff_rc}  ${json_diff_file_path}
    # Description of argument(s):
    # diff_rc              The failing return code from the difference check.
    # json_diff_file_path  The file that has the latest inventory snapshot.

    Log To Console  Significant difference in inventory found, rc=${diff_rc}
    Log To Console  Differences are listed in file:  no_newline=true
    Log To Console  ${json_diff_file_path}
    Log To Console  File Contents:
    Wait Until Created  ${json_diff_file_path}
    ${file_contents}=  OperatingSystem.Get File  ${json_diff_file_path}
    Log  ${file_contents}  level=WARN
    Fail  Significant difference in inventory found, rc=${diff_rc}


Loop HTX Health Check
    [Documentation]  Run until HTX exerciser fails.
    Repeat Keyword  ${HTX_DURATION}
    ...  Run Keywords  Check HTX Run Status
    ...  AND  Check For Error Logs  ${ESEL_IGNORE_LIST}
    ...  AND  Sleep  ${HTX_INTERVAL}


Test Setup Execution
    [Documentation]  Do the initial test setup.

    ${bmc_version}  ${stderr}  ${rc}=  BMC Execute Command
    ...  cat /etc/os-release
    Printn
    Rprint Vars  bmc_version

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
    IF  '${status}' == 'True'  Shutdown HTX Exerciser


Test Teardown Execution
    [Documentation]  Do the post-test teardown.

    # Keep HTX running if user set HTX_KEEP_RUNNING to 1.
    IF  '${TEST_STATUS}' == 'FAIL' and ${HTX_KEEP_RUNNING} == ${0}
        Shutdown HTX Exerciser
    END

    ${keyword_buf}=  Catenate  Stop SOL Console Logging
    ...  \ targ_file_path=${EXECDIR}${/}logs${/}SOL.log
    Run Keyword And Ignore Error   ${keyword_buf}

    FFDC On Test Case Fail
    Close All Connections
