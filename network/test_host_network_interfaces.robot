*** Settings ***

Documentation  Verify that the OS network interfaces are configured and
...  stable.

# TEST PARAMETERS:
#   OS_HOST                     The OS host name or IP address.
#   OS_USERNAME                 The OS user name.
#   OS_PASSWORD                 The OS Host password.
#   FAIL_ON_LINK_DOWN           If set to 1, the test will exit if
#                               a link is down. Default is 1.

Resource         ../syslib/utils_install.robot

*** Variables ***
${FAIL_ON_LINK_DOWN}  1


*** Test Cases ***
Verify Network Interfaces
    [Documentation]  Verify the states of all system interfaces.
    [Tags]  Verify_Network_Interfaces

    Rprintn
    REST Power On
    @{interface_names}=  Get OS Network Interface Names
    :FOR  ${interface_name}  IN  @{interface_names}
    \  ${ethtool_dict}=  Get OS Ethtool  ${interface_name}
    \  Run Keyword If  ${FAIL_ON__LINK_DOWN} == 1
    \  ...  Should Be Equal  ${ethtool_dict['link_detected']}  yes
    \  ...  msg=Link ${interface_name} is down.
