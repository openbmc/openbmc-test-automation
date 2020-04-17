***Settings ***

Documentation    Testsuite for verify security requirements.
Resource         ../lib/resource.robot
Resource         ../lib/utils.robot
Resource         ../lib/bmc_redfish_resource.robot
Resource         ../lib/connection_client.robot

*** Variables ***

${host}                     ${OPENBMC_HOST}
${username}                 ${OPENBMC_USERNAME}
${password}                 ${OPENBMC_PASSWORD}
@{redfish_status_list}      @{empty}
${iterations}               ${10000}

*** Test Cases ***

Make Large Number Of Wrong Redfish Login Attempts And Check Stability
    [Documentation]  Performs a large number of incorrect login attempts and
    ...  every 100th attempt uses correct login credentials and
    ...  validate all incorrect logs are rejected and all correct logins succeed.
    [Tags]  Make_Large_Number_Of_Wrong_Redfish_Login_Attempts_And_Check_Stability

    Redfish.Login
    Redfish.Patch  ${REDFISH_BASE_URI}AccountService  body=[('AccountLockoutThreshold', 0)]
    FOR  ${i}  IN RANGE   ${1}  ${iterations}
      log To Console  ${i}
      ${invalid_password}=   Catenate  ${password}${i}
      Run Keyword If  ${i} % ${100} != ${0}
      ...  Run Keyword And Ignore Error  Redfish.Login  ${username}  ${invalid_password}

      # Every 100th iteration Login with correct credentials
      ${status}=   Run keyword If  ${i} % ${100} == ${0}  Run Keyword And Return Status
      ...   Redfish.Login  ${username}  ${password}
      Run Keyword If  ${status} == ${False}  Append To List  ${redfish_status_list}  ${status}
    END

    ${verify_count}=  Evaluate  ${iterations}/100
    ${fail_count}=  Get Length  ${ssh_status_list}
    Should Be Equal  ${fail_count}  ${0}  msg= Login Failed ${fail_count} times in ${verify_count} attempts
