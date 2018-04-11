*** Settings ***

Documentation  Verify that the OS network interfaces are configured and
...  stable.

# TEST PARAMETERS:
#   OS_HOST                     The OS host name or IP address.
#   OS_USERNAME        .        The OS Host user name.
#   OS_PASSWORD        .        The OS Host password.
#   EXIT_ON_DOWN                If set to 1, the test will exit if
#                               a link is down.

Resource         ../syslib/utils_install.robot

*** Variables ***


*** Test Cases ***
Verify Network Interfaces
  [Documentation]  Verify the states of all system interfaces.
  [Tags]  Verify_Network_Interfaces

  Login To OS
  @{interfaces}  Get OS Network Interfaces
  :FOR  ${interface}  IN  @{interfaces}
  \  ${state}  Get Network Interface State  ${interface}
  \  Run Keyword If  ${EXIT_ON_DOWN} == 1
  \  ...  Should Be Equal  ${state}  up
  \  ...  msg=Link ${interface} is ${state}