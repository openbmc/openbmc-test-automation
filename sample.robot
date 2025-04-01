*** Settings ***

*** Test cases ***

Testing IPv6

    Delete IPv6 Address  hello

*** Keywords ***

Delete IPv6 Address
    [Documentation]  Delete IPv6 address of BMC.
    [Arguments]  ${ipv6_addr}  ${valid_status_codes}=${200},${204}

    Log To console   ${valid_status_codes}


