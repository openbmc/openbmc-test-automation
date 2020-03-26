***Settings ***

Documentation    Testsuite for verify security requirements.
Resource         ../lib/resource.robot
Resource         ../lib/utils.robot
Resource         ../lib/bmc_redfish_resource.robot
Resource         ../lib/connection_client.robot
Library          SSHLibrary

*** Variables ***

${host}                     ${OPENBMC_HOST}
${username}                 ${OPENBMC_USERNAME}
${password}                 ${OPENBMC_PASSWORD}
@{ssh_status_list}          @{empty}
${iterations}               ${10000}

*** Test Cases ***

Make Large Number Of Wrong SSH Login Attempts And Check Stability
    [Documentation]  Performs a large number of incorrect login attempts and
    ...  every 100th attempt uses correct login credentials.
    ...  Validate all incorrect logs are rejected and all correct logins succeed.
    [Tags]  Make_Large_Number_Of_Wrong_SSH_Login_Attempts_And_Check_Stability

    Redfish.Login
    Redfish.Patch  ${REDFISH_BASE_URI}AccountService  body=[('AccountLockoutThreshold', 0)]

    FOR  ${i}  IN RANGE   ${1}  ${iterations}
      ${invalid_password}=   Catenate  ${password}${i}
      Run keyword If  ${i} % ${100} != 0
      ...  Login To BMC  ${host}  ${username}  ${invalid_password}
      ...  ELSE  Login To BMC  ${host}  ${username}  ${password}
    END

    ${verify_count}=  Evaluate  ${iterations}/100
    ${fail_count}=  Get Length  ${ssh_status_list}
    Should Be Equal  ${fail_count}  ${0}  msg= Login Failed ${fail_count} times in ${verify_count} attempts


*** Keywords ***

Login To BMC
    [Documentation]  Login to BMC Host.
    [Arguments]  ${host}  ${username}  ${password}

    # Description of argument(s):
    # host         HOST IP Adress.
    # username     Host Login user name.
    # password     Host Login passwrd.

    Ping Host  ${host}
    SSHLibrary.Open Connection  ${host}
    ${status}  ${output}=  Run Keyword And Ignore Error  SSHLibrary.Login  ${username}  ${password}
    Run Keyword If  '${status}'== 'FAIL'   Append To List  ${ssh_status_list}   ${status}
    SSHLibrary.Close Connection

