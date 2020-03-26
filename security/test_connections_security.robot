***Settings ***

Documentation    Testsuite to verify security requirements.
Resource         ../lib/resource.robot
Resource         ../lib/utils.robot
Resource         ../lib/bmc_redfish_resource.robot
Resource         ../lib/connection_client.robot
Library          SSHLibrary

Suite Setup      Suite Setup Execution
Suite Teardown   Redfish.Logout

Test Teardown    FFDC On Test Case Fail

*** Variables ***

${host}                     ${OPENBMC_HOST}
${username}                 ${OPENBMC_USERNAME}
${password}                 ${OPENBMC_PASSWORD}
${iterations}               ${10}

*** Test Cases ***

Make Large Number Of Wrong SSH Login Attempts And Check Stability
    [Documentation]  Performs a large number of incorrect login attempts and
    ...  every 100th attempt uses correct login credentials and
    ...  validate all incorrect logins are rejected and all correct logins succeed.
    [Tags]  Make_Large_Number_Of_Wrong_SSH_Login_Attempts_And_Check_Stability

    @{ssh_status_list}=  Create List
    FOR  ${i}  IN RANGE  ${iterations}
      Log To Console  ${i}
      SSHLibrary.Open Connection  ${host}
      ${invalid_password}=   Catenate  ${password}${i}
      Run Keyword If  ${i} % ${100} != ${0}
      ...  Run Keyword And Ignore Error  SSHLibrary.Login  ${username}  ${invalid_password}

      # Every 100th iteration Login with correct credentials
      ${status}=   Run keyword If  ${i} % ${100} == ${0}  Run Keyword And Return Status
      ...   SSHLibrary.Login  ${username}  ${password}
      Run Keyword If  ${status} == ${False}  Append To List  ${ssh_status_list}  ${status}
      SSHLibrary.Close Connection
    END

    ${valid_login_count}=  Evaluate  ${iterations}/100
    ${fail_count}=  Get Length  ${ssh_status_list}
    Should Be Equal  ${fail_count}  ${0}  msg= Login Failed ${fail_count} times in ${valid_login_count} attempts.


*** Keywords ***

Suite Setup Execution
   Redfish.Login
   Redfish.Patch  /redfish/v1/AccountService  body=[('AccountLockoutThreshold', 0)]
