*** Settings ***
Documentation  Network diagnostic tool report and logs to console
...            for information. For more information 'man mtr'.

Library       OperatingSystem
Library       ../lib/utilities.py
Resource      ../lib/utils.robot
Test Setup    Check If Tool Exist

Force Tags  Check_Network_Latency

*** Test Cases ***

Check Network Latency
    [Documentation]  Check network connection between host MTR and BMC host.
    [Tags]  Check_Network_Latency

    Ping Host  ${OPENBMC_HOST}
    Repeat Keyword  3 times  Log Network Loss

*** Keywords ***

Log Network Loss
    [Documentation]  Log Network packets loss percentage from MTR report.
    ${report}=  Get MTR Row  ${OPENBMC_HOST}
    Log To Console  \n Network packets loss: ${report['loss']} percent
    Sleep  3s

Check If Tool Exist
    [Documentation]  Check if mtr tool exists.

    ${bin_path}=  Run  which mtr
    Should Contain  ${bin_path}  mtr  msg=mtr tool is not installed.
