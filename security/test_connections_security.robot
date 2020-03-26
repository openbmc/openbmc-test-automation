*** Settings ***
Documentation    Testsuite for verify security requirements.

Resource         ../lib/resource.robot
Resource         ../lib/bmc_redfish_resource.robot
Library          SSHLibrary

*** Variables ***

${host}                     ${OPENBMC_HOST}
${username}                 ${OPENBMC_USERNAME}
${password}                 ${OPENBMC_PASSWORD}
@{ssh_failed_attempts}      @{empty}
@{redfish_failed_attempts}  @{empty}
${iteration}                ${100}

*** Test Cases ***

Make Large Number Of Wrong SSH Login Attempts And Check Stability
    [Documentation]  Make large number of wrong SSH login attempts and check stability.
    [Tags]  Make_Large_Number_Of_Wrong_SSH_Login_Attempts_And_Check_Stability

    FOR  ${i}  IN RANGE  1   10000
      ${invalid_password}=   Catenate  ${password}${i}
      Open Connection  ${host}
      Run keyword If  ${i} % ${iteration} != 0 
      ...  Run Keywords
      ...  Run Keyword and Ignore Error  SSHLibrary.Login  ${username}  ${invalid_password}
      ...  AND  Append To List  ${ssh_failed_attempts}  ${i}
      ...  ELSE  SSHLibrary.Login   ${username}  ${password}
      Close Connection
    END
    ${count}=  Get Length  ${ssh_failed_attempts}

Make Large Number Of Wrong Redfish Login Attempts And Check Stability
    [Documentation]  Make large number of wrong Redfish login attempts and check stability.
    [Tags]  Make_Large_Number_Of_Wrong_Redfish_Login_Attempts_And_Check_Stability

    FOR  ${i}  IN RANGE  1   10000
      ${invalid_password}=   Catenate  ${password}${i}
      Open Connection  ${host}
      Run keyword If  ${i} % ${iteration} != 0
      ...  Run Keywords
      ...  Run Keyword and Ignore Error  Redfish.Login  ${username}  ${invalid_password}
      ...  AND  Append To List  ${redfish_failed_attempts}  ${i}
      ...  ELSE  Redfish.Login   ${username}  ${password}
      Close Connection
    END
    ${count}=  Get Length  ${redfish_failed_attempts}

  

