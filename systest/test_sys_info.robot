*** Settings ***
Documentation   Display and verify system information.

Library         SSHLibrary
Resource        ../lib/resource.txt
Suite Setup     Open Connection And Login
Suite Teardown  Close All Connections

*** Variables ***
${SYS_MEMORY_COUNT}   ${7} 
${SYS_DIMM_COUNT}     ${4}

*** Test Cases ***
Display And Verify System Info
    ${version}=  Execute Command  pflash -r /dev/stdout -P VERSION
    Log  ${\n}version: ${version}  console=yes

    # Verify inventory.
    ${memory_count}=  Execute Command  lshw -short | grep memory | wc -l
    Should Be Equal As Integers  ${memory_count}  ${SYS_MEMORY_COUNT}
    Log  ${\n}memory_count: ${memory_count}  console=yes
    ${dimm_count}=  Execute Command  lshw -short | grep DIMM | wc -l
    Should Be Equal As Integers  ${dimm_count}  ${SYS_DIMM_COUNT}  Error: DIMM count ${dimm_count} expected ${SYS_DIMM_COUNT}
    Log  ${\n}dimm_count: ${dimm_count}  console=yes

    # Verify HTX Installed.
    ${return_code}=  Execute Command  which ls  return_stdout=False  return_rc=True
    Should Be Equal As integers  ${return_code}  0  Error: HTX is not installed.

    # Verify Opal-Prd Service Installed.
    ${output}=  Execute Command  systemctl status opal-prd.service
    Should Not Contain  ${output}  could not be found  msg=Error: opal-prd.service is not installed.

*** Keywords ***
Open Connection And Login
    Open Connection  ${OS_HOST}
    Login  ${OS_USERNAME}  ${OS_PASSWORD}

