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
@{ssh_failed_attempts}      @{empty}
@{ssh_passed_attempts}      @[empty}
${iterations}               ${10000}

*** Test Cases ***

Make Large Number Of Wrong SSH Login Attempts And Check Stability
    [Documentation]  Make large number of wrong SSH login attempts and check stability.
    [Tags]  Make_Large_Number_Of_Wrong_SSH_Login_Attempts_And_Check_Stability

    FOR  ${i}  IN RANGE  1  ${iterations}
      ${invalid_password}=   Catenate  ${password}${i}
      Run keyword If  ${i} % ${100} != 0
      ...  Login To BMC  ${host}  ${username}  ${invalid_password}  host_wrong_login_connection
      ...  ELSE  Login To BMC  ${host}  ${username}  ${password}
    END

    ${passed_status_count}=  Get Length  ${ssh_passed_attempts}
    ${failed_status_count}=    Get Length  ${ssh_failed_attempts}
    Run Keyword If  ${passed_status_count} == ${9}  Fail
    ...  msg= ${failed_status_count} of logins are failing.

*** Keywords ***

Login To BMC
    [Documentation]  Login to BMC Host.
    [Arguments]  ${host}=${OPENBMC_HOST}  ${username}=${OPENBMC_USERNAME}
    ...          ${password}=${OPENBMC_PASSWORD}
    ...          ${alias_name}=host_connection
    # Description of argument(s):
    # host         IP address of the BMC Host.
    # username     Host Login user name.
    # password     Host Login passwrd.
    # alias_name   Default BMC SSH session connection alias name.

    Ping Host  ${host}
    SSHLibrary.Open Connection  ${host}  alias=${alias_name}
    ${status}  ${output}=  Run Keyword and Ignore Error  SSHLibrary.Login  ${username}  ${password}
    Run Keyword If  '${status}'== 'PASS'   Append To List  ${ssh_passed_attempts}   ${status}
    ...  ELSE  Append To List  ${ssh_failed_attempts}  ${status}
    SSHLibrary.Close Connection
