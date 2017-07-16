*** Settings ***
Documentation  Stress the system using HTX exerciser.

# Test Parameters:
# OPENBMC_HOST        The BMC host name or IP address.
# OS_HOST             The OS  host name or IP Address.
# OS_USERNAME         The OS login userid (usually root).
# OS_PASSWORD         The password for the OS login.
# HTX_DURATION        Duration of HTX run, for example, 8 hoursr, or
#                     30 minutes.
# HTX_LOOP            The Integer number of times to loop HTX.
# HTX_INTERVAL        The time delay between consecutive checks of HTX
#                     status, for example, 30s.
#                     In summary: Run HTX for $HTX_DURATION, looping
#                     $HTX_LOOP times checking every $HTX_INTERVAL.
# HTX_KEEP_RUNNING    If set to 1, this indicates that the HTX is to
#                     continue running after an error.
# INVENTORY           If set to 1, this enables OS inventory checking
#                     before and after each HTX run.
# PREV_INV_FILE_PATH  The file path and name of a previous inventroy
#                     snapshot file.  This parameter is optional.
#                     After HTX start the system inventory
#                     will be compared to the contents of this file.

Resource         ../syslib/utils_os.robot
Library          ../syslib/utils_keywords.py

Suite Setup     Run Key  Start SOL Console Logging
Test Setup      Pre Test Case Execution
Test Teardown   Post Test Case Execution

*** Variables ****

${stack_mode}                skip
${json_initial_file_path}    ${EXECDIR}/data/os_inventory_initial.json
${json_final_file_path}      ${EXECDIR}/data/os_inventory_final.json
${json_diff_file_path}       ${EXECDIR}/data/os_inventory_diff.json
${last_inv_file_path}        0
&{ignore_dict}               processor=size

*** Test Cases ***

Hard Bootme Test
    [Documentation]  Stress the system using HTX exerciser.
    [Tags]  Hard_Bootme_Test

    Rprintn
    Rpvars  HTX_DURATION  HTX_INTERVAL

    # set last inventory file name and path to PREV_INV_FILE_PATH if it
    # was defined by the caller, otherwise set it to 0
    ${last_inv_file_path}=  Get Variable Value
    ...  ${PREV_INV_FILE_PATH}  ${0}
    Set Global Variable  ${last_inv_file_path}

    Repeat Keyword  ${HTX_LOOP} times  Start HTX Exerciser


*** Keywords ***

Start HTX Exerciser
    [Documentation]  Start HTX exerciser.
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

    Boot To OS

    # Post Power off and on, the OS SSH session needs to be established.
    Login To OS

    ${run_the_inventory}=  Get Variable Value  ${INVENTORY}  ${0}
    Run Keyword If  '${run_the_inventory}' != '${0}'
    ...  Do Inventory And Compare
    ...  ${json_initial_file_path}

    Run Keyword If  '${HTX_MDT_PROFILE}' == 'mdt.bu'
    ...  Create Default MDT Profile

    Run MDT Profile

    Loop HTX Health Check

    Shutdown HTX Exerciser

    Run Keyword If  '${run_the_inventory}' != '${0}'
    ...  Do Inventory And Compare
    ...  ${json_final_file_path}

    Power Off Host

    # Close all SSH and REST active sessions.
    Close All Connections
    Flush REST Sessions

    Rprint Timen  HTX Test ran for: ${HTX_DURATION}


Do Inventory and Compare
    [Documentation]  Run inventory.
    [Arguments]  ${do_inv_to_this_file_path}
    # Description of argument:
    # do_inv_to_this_file_path   The file to receive the inventory snapshot
    #

    Create JSON Inventory File  ${do_inv_to_this_file_path}
    Run Keyword If  '${last_inv_file_path}' != '${0}'
    ...  Compare Inventory Files  ${do_inv_to_this_file_path}
    ${last_inv_file_path}=   Set Variable  ${do_inv_to_this_file_path}
    Set Global Variable  ${last_inv_file_path}


Compare Inventory Files
    [Documentation]  Compare contents of inventory files.
    [Arguments]  ${do_inv_to_this_file_path}
    # Description of argument:
    # do_inv_to_this_file_path   The file that now has inventory snapshot.
    #

    ${diff_rc}=  json_inv_file_diff_check  ${do_inv_to_this_file_path}
     ...  ${last_inv_file_path}  ${json_diff_file_path}  ${ignore_dict}
    Run Keyword If  '${diff_rc}' != '${0}'
    ...  Report Inventory Mismatch  ${diff_rc}


Report Inventory Mismatch
    [Documentation]  Report a difference between inventory files
    [Arguments]  ${diff_rc}
    # Description of argument:
    # diff_rc  the failing return code from json_inv_file_diff_check

    Log To Console  Difference in inventory found, return code:   no_newline=true
    Log to Console  ${diff_rc}
    Log to Console  Differences are listed in file:  no_newline=true
    Log to Console  ${json_diff_file_path}
    Log  Ending test case execution due to inventory mistmatch.  ERROR
    Should Be Equal As Integers  ${diff_rc}  0


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
    Run Keyword If
    ...  '${TEST_STATUS}' == 'FAIL' and ${HTX_KEEP_RUNNING} == ${0}
    ...  Shutdown HTX Exerciser

    ${keyword_buf}=  Catenate  Stop SOL Console Logging
    ...  \ targ_file_path=${EXECDIR}${/}logs${/}SOL.log
    Run Key  ${keyword_buf}

    FFDC On Test Case Fail
    Close All Connections
