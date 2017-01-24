*** Settings ***
Documentation  Network diagnostic tool report and logs to console
...            for information. For more information 'man mtr'.

Library       OperatingSystem
Library       ../lib/utilities.py
Resource      ../lib/utils.robot
Test Setup    Check If Tool Exist

*** Test Cases ***

Check Network Latency
    [Documentation]  Check network connection between the host mtr
    ...              and BMC host.

    Ping Host  ${OPENBMC_HOST}
    Repeat Keyword  3 times  MTR Scan Report

*** Keywords ***

MTR Scan Report
    [Documentation]  MTR scan loss report.
    ${report}=  Get MTR Row  ${OPENBMC_HOST}
    Log To Console  \n Network packet dropped: ${report['loss']} percent

Check If Tool Exist
    [Documentation]  Check if mtr tool exist.

    ${bin_path}=  Run  which mtr
    Should Contain  ${bin_path}  mtr  msg=mtr tool is not installed.
