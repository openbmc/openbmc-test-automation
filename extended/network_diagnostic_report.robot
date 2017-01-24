*** Settings ***
Documentation  Network diagnostic tool report and logs to console
...            for information. For more information 'man mtr'.

Library       OperatingSystem
Resource      ../lib/utils.robot
Test Setup    Check If Tool Exist

*** Test Cases ***

Check Network Latency
    [Documentation]  Check network connection between the host mtr
    ...              and BMC host.

    Ping Host  ${OPENBMC_HOST}
    Repeat Keyword  3 times  Scan MTR Report


*** Keywords ***

MTR Scan Report
    [Documentation]  MTR scan report.

    ${report}=  Run  mtr --report ${OPENBMC_HOST}
    Should Contain  ${report}  Loss  msg=MTR Scan error
    Log To Console  \n ${report}
    ${bmc_resp}=  Get Lines Containing String  ${report}  ${OPENBMC_HOST}
    ${strip_out}=  Set Variable  ${bmc_resp.split('--')[1].split('.0%')[0]}
    ${percent}=  Convert To Integer  ${strip_out.rsplit(' ',1)[1]}

    Log To Console  \n Network packet dropped: ${percent} percent.
    Sleep  3s


Check If Tool Exist
    [Documentation]  Check if mtr tool exist.

    ${bin_path}=  Run  which mtr
    Should Contain  ${bin_path}  mtr  msg=mtr tool is not installed.
