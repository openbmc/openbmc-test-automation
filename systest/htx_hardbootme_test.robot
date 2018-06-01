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

Resource        ../syslib/utils_os.robot
Resource        ../lib/openbmc_ffdc_utils.robot
Resource        ../lib/logging_utils.robot
Library         ../syslib/utils_keywords.py
Library         ../lib/utils_files.py
Library         ../lib/logging_utils.py

Suite Setup     Run Keyword  Start SOL Console Logging
Test Setup      Test Setup Execution
Test Teardown   Test Teardown Execution


*** Variables ****

${stack_mode}                skip
${json_initial_file_path}    ${EXECDIR}/os_inventory_initial.json
${json_final_file_path}      ${EXECDIR}/os_inventory_final.json
${json_diff_file_path}       ${EXECDIR}/os_inventory_diff.json
${CHECK_INVENTORY}           True
${INV_IGNORE_LIST}           size
${PREV_INV_FILE_PATH}        NONE


*** Test Cases ***

Hard Bootme Test
    [Documentation]  Stress the system using HTX exerciser.
    [Tags]  Hard_Bootme_Test

    Rprintn
    Rpvars  HTX_DURATION  HTX_LOOP  HTX_INTERVAL  CHECK_INVENTORY
    ...  INV_IGNORE_LIST  PREV_INV_FILE_PATH

    Run Keyword If  '${PREV_INV_FILE_PATH}' != 'NONE'
    ...  OperatingSystem.File Should Exist  ${PREV_INV_FILE_PATH}

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
    Rprintn
    Rpvars  loop_count  estimated_loop_time   estimated_time_remaining

    REST Power On  stack_mode=skip
    Run Key U  Sleep \ 15s

    # Post Power off and on, the OS SSH session needs to be established.
    Login To OS

    Run Keyword If  '${CHECK_INVENTORY}' == 'True'
    ...  Do Inventory And Compare  ${json_initial_file_path}
    ...  ${PREV_INV_FILE_PATH}

    Run Keyword If  '${HTX_MDT_PROFILE}' == 'mdt.bu'
    ...  Create Default MDT Profile

    Run MDT Profile

    Loop HTX Health Check

    Shutdown HTX Exerciser

    Run Keyword If  '${CHECK_INVENTORY}' == 'True'
    ...  Do Inventory And Compare  ${json_final_file_path}
    ...  ${PREV_INV_FILE_PATH}

    # Terminate run if there are any BMC error logs.
    ${error_logs}=  Get Error Logs
    ${num_logs}=  Get Length  ${error_logs}
    Run Keyword If  ${num_logs} != 0  Run Keywords
    ...  Print Error Logs  ${error_logs}
    ...  AND  Fail  msg=Terminating run due to BMC error log(s).

    Power Off Host

    # Close all SSH and REST active sessions.
    Close All Connections
    Flush REST Sessions

    Rprint Timen  HTX Test ran for: ${HTX_DURATION}

    ${loop_count}=  Catenate  Ending iteration: ${iteration}

    ${est_seconds_left}=  Evaluate  ${est_seconds_left}-${loop_body_seconds}
    Set Suite Variable  ${est_seconds_left}  children=true
    ${estimated_time_remaining}=  Convert Time
    ...  ${est_seconds_left}  result_format=compact

    Rpvars  loop_count  estimated_time_remaining


Do Inventory And Compare
    [Documentation]  Do inventory and compare.
    [Arguments]  ${inventory_file_path}  ${PREV_INV_FILE_PATH}
    # Description of argument(s):
    # inventory_file_path  The file to receive the inventory snapshot.
    # PREV_INV_FILE_PATH   The previous inventory to compare with.

    Create JSON Inventory File  ${inventory_file_path}
    Run Keyword If  '${PREV_INV_FILE_PATH}' != 'NONE'
    ...  Compare Json Inventory Files  ${inventory_file_path}
    ...  ${PREV_INV_FILE_PATH}
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
    Run Keyword If  '${diff_rc}' != '${0}'
    ...  Report Inventory Mismatch  ${diff_rc}  ${json_diff_file_path}
    ...  ELSE  Rprint Timen  Inventoy check: No differences found.


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
    ...  AND  Sleep  ${HTX_INTERVAL}


Test Setup Execution
    [Documentation]  Do the initial test setup.

    REST Power On  stack_mode=skip
    Run Key U  Sleep \ 15s
    Delete All Error Logs
    Tool Exist  htxcmdline

    # Shutdown if HTX is running.
    ${status}=  Is HTX Running
    Run Keyword If  '${status}' == 'True'
    ...  Shutdown HTX Exerciser


Test Teardown Execution
    [Documentation]  Do the post test teardown.
    # 1. Shut down HTX exerciser if test Failed.
    # 2. Capture FFDC on test failure.
    # 3. Close all open SSH connections.

    # Keep HTX running if user set HTX_KEEP_RUNNING to 1.
    Run Keyword If
    ...  '${TEST_STATUS}' == 'FAIL' and ${HTX_KEEP_RUNNING} == ${0}
    ...  Shutdown HTX Exerciser

    ${keyword_buf}=  Catenate  Stop SOL Console Logging
    ...  \ targ_file_path=${EXECDIR}${/}logs${/}SOL.log
    Run Key  ${keyword_buf}

    FFDC On Test Case Fail
    Close All Connections
