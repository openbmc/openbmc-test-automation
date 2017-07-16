*** Settings ***
Documentation    Stress the system using HTX exerciser.

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

*** Test Cases ***

Hard Bootme Test
    [Documentation]  Stress the system using HTX exerciser.
    [Tags]  Hard_Bootme_Test

    Rprintn
    Rpvars  HTX_DURATION  HTX_INTERVAL

    Repeat Keyword  ${HTX_LOOP} times  Start HTX Exerciser


*** Keywords ***

Start HTX Exerciser
    [Documentation]  Start HTX exerciser.
    # Test Flow:
    #              - Power on
    #              - Establish SSH connection session
    #              - Create HTX mdt profile
    #              - Run HTX exerciser
    #              - Check HTX status for errors
    #              - Power off

    Boot To OS

    # Post Power off and on, the OS SSH session needs to be established.
    Login To OS
    
    Log To Console   Getting initial OS inventory                  
    Create JSON Inventory File   ${json_file_initial}      

    #Run Keyword If  '${HTX_MDT_PROFILE}' == 'mdt.bu'
    #...  Create Default MDT Profile

    #Run MDT Profile

    #Loop HTX Health Check

    #Shutdown HTX Exerciser

    Log To Console   Getting final OS inventory                  
    Create JSON Inventory File    ${json_file_final}

    Log to Console   Comparing initial and final OS inventories                  
    OperatingSystem.File Should Exist   ${json_file_initial}
    OperatingSystem.File Should Exist   ${json_file_final}
    ${diff_rc}=  json_inv_file_diff_check     ${json_file_initial}   
    ...  ${json_file_final}     ${json_diff_file}
    Should Be Equal As Integers    ${diff_rc}    0 

    #Power Off Host

    # Close all SSH and REST active sessions.
    Close All Connections
    Flush REST Sessions

    Rprint Timen  HTX Test ran for: ${HTX_DURATION}


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
