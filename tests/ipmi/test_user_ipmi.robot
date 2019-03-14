*** Settings ***
Documentation       This suite is for testing general IPMI functions.

Resource            ../../lib/ipmi_client.robot
Resource            ../../lib/openbmc_ffdc.robot

Test Teardown       Test Teardown Execution

*** Variables ***

${test_password}   0penBmc123

*** Test Cases ***

Verify IPMI Default Password Update
    [Documentation]  Update IPMI default password and verify.
    [Tags]  Verify_IPMI_Default_Password_Update

    Run IPMI Standard Command  power status

    # Change IPMI default admin password.
    ${ipmi_cmd_update}=  Catenate  SEPARATOR=  ipmitool -I lanplus -C ${IPMI_CIPHER_LEVEL}
    ...  ${SPACE}-U admin -P ${IPMI_PASSWORD} -H ${OPENBMC_HOST} user set password 1 ${test_password}

    ${rc}  ${output}=  Run And Return RC and Output  ${ipmi_cmd_update}
    Should Be Equal  ${rc}  ${0}

    # IPMI query using new password.
    ${ipmi_cmd_query}=  Catenate  SEPARATOR=  ipmitool -I lanplus -C ${IPMI_CIPHER_LEVEL}
    ...  ${SPACE}-U admin -P ${test_password} -H ${OPENBMC_HOST} power status

    ${rc}  ${output}=  Run And Return RC and Output  ${ipmi_cmd_query}
    Should Be Equal  ${rc}  ${0}


*** Keywords ***

Test Teardown Execution
    [Documentation]  Do test teardown task.

    FFDC On Test Case Fail

    # Change IPMI default Admin password.
    ${ipmi_cmd_default}=  Catenate  SEPARATOR=  ipmitool -I lanplus -C ${IPMI_CIPHER_LEVEL}
    ...  ${SPACE}-U admin -P ${test_password} -H ${OPENBMC_HOST} user set password 1 ${IPMI_PASSWORD}

    ${rc}  ${output}=  Run And Return RC and Output  ${ipmi_cmd_default}
    Should Be Equal  ${rc}  ${0}

