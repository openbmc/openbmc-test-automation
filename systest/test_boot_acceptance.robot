*** Settings ***
Documentation  Make a general hardware stress in a partition with all the
...  resources available.

# Test Parameters:
# TYPE                EEH error function to use, default is 4.
# OPENBMC_HOST        The BMC host name or IP address.
# OS_HOST             The OS host name or IP Address.
# OS_USERNAME         The OS login userid (usually root).
# OS_PASSWORD         The password for the OS login.
# HTX_DURATION        Duration of HTX run (e.g. "24 hours", "8 hours").
# HTX_INTERVAL        The time delay between consecutive checks of HTX
#                     status, for example, 30 minutes.
#                     In summary: Run HTX for $HTX_DURATION, checking
#                     every $HTX_INTERVAL.
# HTX_MDT_PROFILE     MDT profile to be executed (e.g. "mdt.bu, net.mdt, etc")
#                     default is "mdt.bu".
# bootme_period       Bootme period where the system will be rebooting. (e.g.
#                     "3") 3 = 1 hour period.

# Expected result:
# HTX runs mdt.bu and doesn't log errors during the acceptance execution.

# Glossary:
# MDT:
#   Master device table is a collection of hardware devices on the system for
#   which HTX exercisers can be run.
# build_net:
#   Script that configures every network port when connected to a loop. This
#   skips the communication port to always keep it available.
# mdt.bu:
#   Default mdt file. Collection of all HTX exercisers. Aim is to test entire
#   system concurrently.
# HTX error log file /tmp/htxerr
#   Records all the errors that occur. If there's no error during the test, it
#   should be empty.
# bootme:
#   This configures the cron to reboot the system and re-run the HTX profile.

Library         SSHLibrary
Library         String
Library         ../lib/bmc_ssh_utils.py
Resource        ../lib/resource.robot
Resource        ../syslib/utils_os.robot
Resource        ../lib/bmc_network_utils.robot

Suite Setup     Suite Setup Execution
Suite Teardown  Collect HTX Log Files
Test Teardown   FFDC On Test Case Fail

*** Variables ***

${HTX_DURATION}     8 hours
${HTX_INTERVAL}     35 minutes
${HTX_MDT_PROFILE}  mdt.bu
${bootme_period}    3

*** Test Cases ***

Test Acceptance IPL
    [Documentation]  Stress every controller connected via PCI in an OS with
    ...  every resource available (CPU, RAM, storage, ethernet controllers,
    ...  etc).
    [Tags]  Test_Acceptance_IPL

    Run Build Net
    Run MDT Profile  ${HTX_MDT_PROFILE}
    Run Soft Bootme
    Repeat Keyword  ${HTX_DURATION}  Run Keywords
    ...  Wait Until Keyword Succeeds  15 min  30 sec  Is OS Booted
    ...  AND
    ...  OS Execute Command  uptime
    ...  AND
    ...  Run Key U  sleep \ ${HTX_INTERVAL}
    ...  AND
    ...  Check HTX Run Status
    ...  AND
    ...  Wait Until Keyword Succeeds  20 min  10 sec  Is Host Off
    Wait Until Keyword Succeeds  15 min  15 sec  Is OS Booted
    Shutdown Bootme
    Shutdown HTX Exerciser

*** Keywords ***
Suite Setup Execution
    [Documentation]  Do setup tasks.

    REST Power On  stack_mode=normal
    Tool Exist  htxcmdline
    Create Default MDT Profile
