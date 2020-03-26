*** Settings ***
Documentation    Testsuite for verify securiy requirements.

Resource         ../lib/resource.robot
Resource         ../lib/bmc_redfish_resource.robot
Library          SSHLibrary

*** Variables ***

${username}       ${OPENBMC_USERNAME}
${password}       ${OPENBMC_PASSWORD}

*** Test Cases ***

Test For SSH Wrong Login Attempt
    [Documentation]  Verify SSH wrong login attempt.
    [Tags]  Test_For_SSH_Wrong_Login_Attempt

    FOR  ${i}  IN RANGE  1   11
      ${invalid_password}=   Catenate  ${password}  ${i}
      Open Connection  ${OPENBMC_HOST}
      ${status}  Run Keyword and Return Status  SSHLibrary.Login  ${username}  ${invalid_password}
      Should Be Equal As Strings  ${status}  ${False}
      Close Connection
    END

Test For Redfish Wrong Login Attempt
    [Documentation]  Verify Redfish wrong login attempt.
    [Tags]  Test_For_Wrong_Login_Attempt

    FOR  ${i}  IN RANGE  1   11
      ${invalid_password}=   Catenate  ${password}  ${i}
      ${status}  Run Keyword and Return Status  Redfish.Login  ${username}  ${invalid_password}
      Should Be Equal As Strings  ${status}  ${False}
    END

