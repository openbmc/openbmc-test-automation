*** Settings ***
Documentation    Stress the system using HTX exerciser.

# Test Parameters:
#  OPENBMC_HOST  The BMC IPAddress
#  OS_HOST       The OS IPAddress
#  OS_USERNAME   OS login userid (usually root)
#  OS_PASSWORD   OS login password
#  HTX_LOOP      Integer number of times to loop HTX, e.g. 4
#  HTX_DURATION  The number of times to check HTX status after
#                 a run, e.g. 1
#  HTX_INTERVAL  The time delay between consecutive checks of HTX
#                status, e.g. 20s
#  HTX_KEEP_RUNNING  Set this to be non-zero of you want HTX to
#                    keep running after an error
#  INVENTORY    Set this to a non-zero value to enable inventory 
#               checking after each HTX run
#  PREVIOUS_INVENTORY  The file name of a previous inventroy file.
#                      After each HTX run inventory will be compared
#                      to the contents of this file.
#                      If this parameter is not specified, and
#                      initial inventory snapshot will be taked
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
${looped_once}          0 

*** Test Cases ***

Hard Bootme Test
    [Documentation]  Stress the system using HTX exerciser.
    [Tags]  Hard_Bootme_Test

    Rprintn
    Rpvars  HTX_DURATION  HTX_INTERVAL

    ${temp_value}=   Get Variable Value   ${INVENTORY}   ${0}
    Run Keyword If   '${temp_value}' == '${0}'
    ...   Repeat Keyword  ${HTX_LOOP} times
    ...    Start HTX Exerciser No Inventory
    ...   ELSE  Repeat Keyword  ${HTX_LOOP} times
    ...    Start HTX Exerciser With Inventory    ${looped_once}


*** Keywords ***

Start HTX Exerciser With Inventory
    [Documentation]  Start HTX exerciser with inventory
    [Arguments]      ${looped_once}
    # Test Flow:
    #              - Power on
    #              - Establish SSH connection session
    #              - On the first boot only, set up
    #                the initial file to check inventory against
    #              - Create HTX mdt profile
    #              - Run HTX exerciser
    #              - Check HTX status for errors
    #              - Check inventory after HTX is shutdown
    #              - Power off

    Boot To OS

    # Post Power off and on, the OS SSH session needs to be established.
    Login To OS

    # On the very first boot:
    #  If we have an inventory filename specified, we will use
    #   that file to compare inventory runs against.
    #  If no file is initially specified we will use the default
    #   filename and take an initial inventory snapshot to that file.
    Run Keyword If    '${looped_once}' == '${0}'
    ...   Do On Firstboot Only    ${looped_once}

    Run Keyword If  '${HTX_MDT_PROFILE}' == 'mdt.bu'
    ...  Create Default MDT Profile

    Run MDT Profile

    Loop HTX Health Check

    Shutdown HTX Exerciser

    Create JSON Inventory File    ${json_file_final}

    ${diff_rc}=  json_inv_file_diff_check     ${json_file_initial}
    ...  ${json_file_final}     ${json_diff_file}
    Should Be Equal As Integers    ${diff_rc}    0

    Power Off Host

    # Close all SSH and REST active sessions.
    Close All Connections
    Flush REST Sessions

    Rprint Timen  HTX Test ran for: ${HTX_DURATION}


Start HTX Exerciser No Inventory
    [Documentation]  Start HTX exerciser no inventory.

    Boot To OS

    # Post Power off and on, the OS SSH session needs to be established.
    Login To OS

    Run Keyword If  '${HTX_MDT_PROFILE}' == 'mdt.bu'
    ...  Create Default MDT Profile

    Run MDT Profile

    Loop HTX Health Check

    Shutdown HTX Exerciser

    Power Off Host

    # Close all SSH and REST active sessions.
    Close All Connections
    Flush REST Sessions

    Rprint Timen  HTX Test ran for: ${HTX_DURATION}


Loop HTX Health Check
    [Documentation]  Run until HTX exerciser fails.
    Repeat Keyword  ${HTX_DURATION}
    ...  Run Keywords  Check HTX Run Status
    ...  AND  Sleep  ${HTX_INTERVAL}

Do On Firstboot Only
    [Arguments]        ${looped_once}
    # set looped_once so we  Do On Firstboot Only  only once
    ${looped_once}=     Set Variable     ${1}
    Set Global Variable    ${looped_once}
    # if PREVIOUS_INVENTORY is specified on the invocation command line
    ${temp_value}=   Get Variable Value   ${PREVIOUS_INVENTORY}   ${0}
    Run Keyword If      '${temp_value}' != '${0}'
    ...   Set Initial Inventory Filename
    ...   ELSE   Get Initial Inventory To Default File
 
Set Initial Inventory Filename
    # set the json initial filename from INITIAL INVENTORY parameter 
    ${json_file_initial}=     Set Variable     ${PREVIOUS_INVENTORY}
    Set Global Variable  ${json_file_initial}
    OperatingSystem.File Should Exist   ${json_file_initial}

Get Initial Inventory To Default File
    # create an initial inventory 
    Create JSON Inventory File    ${json_file_initial}


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
