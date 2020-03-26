***Settings ***
Documentation    Testsuite to verify security requirements.

Resource         ../lib/resource.robot
Resource         ../lib/utils.robot
Resource         ../lib/bmc_redfish_resource.robot
Resource         ../lib/connection_client.robot
Library          SSHLibrary

Test Teardown    FFDC On Test Case Fail

*** Variables ***

${iterations}  ${10000}

*** Test Cases ***

Check SSH Wrong Login Attempt With Many Requests
    [Documentation]  Check BMC stability with large number of SSH wrong login requests.
    [Tags]  Make_Large_Number_Of_Wrong_SSH_Login_Attempts_And_Check_Stability
    [Setup]  Set Account Lockout Threshold
    [Teardown]  Redfish.Logout

    @{ssh_status_list}=  Create List
    FOR  ${i}  IN RANGE  ${iterations}
      Log To Console  ${i}
      SSHLibrary.Open Connection  ${OPENBMC_HOST}
      ${invalid_password}=   Catenate  ${OPENBMC_PASSWORD}${i}
      Run Keyword And Ignore Error  SSHLibrary.Login  ${OPENBMC_USERNAME}  ${invalid_password}

      # Every 100th iteration Login with correct credentials
      ${status}=   Run key word If  ${i} % ${100} == ${0}  Run Keyword And Return Status
      ...   SSHLibrary.Login  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}
      Run Keyword If  ${status} == ${False}  Append To List  ${ssh_status_list}  ${status}
      SSHLibrary.Close Connection
    END

    ${valid_login_count}=  Evaluate  ${iterations}/100
    ${fail_count}=  Get Length  ${ssh_status_list}
    Should Be Equal  ${fail_count}  ${0}  msg= Login Failed ${fail_count} times in ${valid_login_count} attempts.


*** Keywords ***

Set Account Lockout Threshold
   [Documentation]  Set user account lockout threshold.

   Redfish.Login
   Redfish.Patch  /redfish/v1/AccountService  body=[('AccountLockoutThreshold', 0)]
