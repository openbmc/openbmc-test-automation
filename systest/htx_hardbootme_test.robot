*** Settings ***
Documentation    Stress the system using HTX exerciser.

Library          ../syslib/utils_keywords.py
Resource         ../syslib/utils_os.robot
Suite Setup      Power Off Host
Suite Teardown   Shutdown HTX Exerciser

*** Variables ****

# Default duration and interval of HTX exerciser to run.
${HTX_DURATION}     4 hours
${HTX_INTERVAL}     15 min

*** Test Cases ***

Hard Bootme Test
    [Documentation]  Stress the system using HTX exerciser.

    Log To Console  \n HTX Test run: ${HTX_DURATION} interval: ${HTX_INTERVAL}
    Login To OS

    Log To Console  \n *** Create HTX mdt profile ***
    ${profile}=  Execute Command On OS  htxcmdline -createmdt
    Log To Console  \n ${profile}
    Should Contain  ${profile}  mdts are created successfully

    Log To Console  \n *** Start HTX mdt profile execution ***
    ${htx_run}=  Execute Command On OS  htxcmdline -run -mdt mdt.bu
    Log To Console  \n ${htx_run}
    Should Contain  ${htx_run}  Activated

    Loop HTX Health Check

*** Keywords ***

Loop HTX Health Check
    [Documentation]  Run until keyword fails.
    Repeat Keyword  ${HTX_DURATION}
    ...  Run Keywords  Check HTX Run Status
    ...  AND  Sleep  ${HTX_INTERVAL}


Check HTX Run Status
    [Documentation]  Get HTX exerciser status and check for error.

    Log To Console  \n *** Check HTX mdt Status and error ***
    ${status}=  Execute Command On OS  htxcmdline -status -mdt mdt.bu
    Log  ${status}

    ${errlog}=  Execute Command On OS  htxcmdline -geterrlog
    Log  ${errlog}

    Should Contain  ${errlog}  file </tmp/htxerr> is empty


Shutdown HTX Exerciser
    [Documentation]  Shut down HTX exerciser run.

    Log To Console  \n *** Shutdown HTX Run ***
    ${shutdown}=  Execute Command On OS  htxcmdline -shutdown -mdt mdt.bu
    Log To Console  \n ${shutdown}
    Should Contain  ${shutdown}  shutdown successfully

    # Power Off only if there is no error
    Run Keyword If  '${TEST_STATUS}' == 'FAIL'
    ...  Power Off Host

Power Off Host
    [Documentation]  Power off host.
    Initiate Host PowerOff
    Wait Until Keyword Succeeds  5 min  10 sec  Is OS Off
