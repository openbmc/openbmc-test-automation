*** Settings ***
Documentation    Stress the system using HTX exerciser.

# Test Parameters:
#  OPENBMC_HOST        The BMC IPAddress.
#  OS_HOST             The OS IPAddress.
#  OS_USERNAME         OS login userid (usually root).
#  OS_PASSWORD         OS login password.
#  HTX_LOOP            Integer number of times to loop HTX, e.g. 4
#  HTX_DURATION        The number of times to check HTX status after
#                      a run, e.g. 1
#  HTX_INTERVAL        The time delay between consecutive checks of HTX
#                      status, e.g. 20s
#  HTX_KEEP_RUNNING    Set this to be non-zero of you want HTX to
#                      keep running after an error.
#  INVENTORY           Set this to a non-zero value to enable inventory
#                      checking after each HTX run.
#  PREVIOUS_INVENTORY  The file name of a previous inventroy file.
#                      After each HTX run inventory will be compared
#                      to the contents of this file.
#                      If this parameter is not specified, an
#                      initial inventory snapshot will be taken
#                      before HTX begins.

Resource         ../syslib/utils_os.robot
Library          ../syslib/utils_keywords.py

Suite Setup     Run Key  Start SOL Console Logging
Test Setup      Pre Test Case Execution
Test Teardown   Post Test Case Execution

*** Variables ****

${stack_mode}           skip
${json_file_initial}    ${EXECDIR}${/}data${/}os_inventory_initial.json
${json_file_final}      ${EXECDIR}${/}data${/}os_inventory_final.json
${json_diff_file}       ${EXECDIR}${/}data${/}os_inventory_diff.json
${last_inv_name}        0

*** Test Cases ***

Hard Bootme Test
    [Documentation]  Stress the system using HTX exerciser.
    [Tags]  Hard_Bootme_Test

    Rprintn
    Rpvars  HTX_DURATION  HTX_INTERVAL

    # set last inventory file name to PREVIOUS INVENTORY if it was
    # defined by the caller, otherwise set it to 0
    ${last_inv_name}=   Get Variable Value   ${PREVIOUS_INVENTORY}   ${0}
    Set Global Variable      ${last_inv_name}

    Repeat Keyword    ${HTX_LOOP} times    Start HTX Exerciser


*** Keywords ***

Start HTX Exerciser
    [Documentation]  Start HTX exerciser
    # Test Flow:
    #              - Power on
    #              - Establish SSH connection session
    #              - Do inventory collection, compare with
    #                previous inventory run if applicable
    #              - Create HTX mdt profile
    #              - Run HTX exerciser
    #              - Check HTX status for errors
    #              - Do inventory collection, compare with
    #                previous inventory run
    #              - Power off

    Boot To OS

    # Post Power off and on, the OS SSH session needs to be established.
    Login To OS

    ${run_the_inventory}=   Get Variable Value   ${INVENTORY}   ${0}
    Run Keyword If   '${run_the_inventory}' != '${0}'
    ...   Do Inventory And Compare
    ...    ${json_file_initial}   ${last_inv_name}   ${json_diff_file}

    Run Keyword If  '${HTX_MDT_PROFILE}' == 'mdt.bu'
    ...  Create Default MDT Profile

    Run MDT Profile

    Loop HTX Health Check

    Shutdown HTX Exerciser

    Run Keyword If   '${run_the_inventory}' != '${0}'
    ...  Do Inventory And Compare
    ...   ${json_file_final}   ${last_inv_name}   ${json_diff_file}

    Power Off Host

    # Close all SSH and REST active sessions.
    Close All Connections
    Flush REST Sessions

    Rprint Timen  HTX Test ran for: ${HTX_DURATION}


Do Inventory and Compare
    [Documentation]   Run inventory
    [Arguments]   ${do_inv_to_this_file}   ${last_inv_name}   ${json_diff_file}
    Create JSON Inventory File    ${do_inv_to_this_file}
    Run Keyword If   '${last_inv_name}' != '${0}'
    ...  Compare Inventory Files
    ...   ${do_inv_to_this_file}  ${last_inv_name}  ${json_diff_file}
    ${last_inv_name}=   Set Variable    ${do_inv_to_this_file}
    Set Global Variable   ${last_inv_name}


Compare Inventory Files
    [Documentation]  Compare contents of inventory files
    [Arguments]   ${do_inv_to_this_file}   ${last_inv_name}   ${json_diff_file}
    ${diff_rc}=  json_inv_file_diff_check    ${do_inv_to_this_file}
     ...   ${last_inv_name}     ${json_diff_file}
    Should Be Equal As Integers    ${diff_rc}    0


Loop HTX Health Check
    [Documentation]  Run until HTX exerciser fails.
    Repeat Keyword  ${HTX_DURATION}
    ...  Run Keywords  Check HTX Run Status
    ...  AND  Sleep  ${HTX_INTERVAL}


Post Test Case Execution
    [Documentation]  Do the post test teardown.
    # 1. Shut down HTX exerciser if test Failed.
    # 2. Capture FFDC on test failure.
    # 3. Close all open SSH connections.

    # Keep HTX running if user set HTX_KEEP_RUNNING to 1.
    Run Keyword If  '${TEST_STATUS}' == 'FAIL' and ${HTX_KEEP_RUNNING} == ${0}
    ...  Shutdown HTX Exerciser

    ${keyword_buf}=  Catenate  Stop SOL Console Logging
    ...  \ targ_file_path=${EXECDIR}${/}logs${/}SOL.log
    Run Key  ${keyword_buf}

    FFDC On Test Case Fail
    Close All Connections
