*** Settings ***
Documentation     Test BMC code update on a target BMC.
...               Execution Command:
...               python -m robot -v OPENBMC_HOST:<hostname>
...               -v IMAGE_FILE_PATH:<path/*.tar>  bmc_code_update.robot

Resource          ../../lib/code_update_utils.robot
Resource          ../../lib/ipmi_client.robot

Suite Setup       Suite Setup Execution


*** Variables ***

${IMAGE_FILE_PATH}                ${EMPTY}
${SKIP_UPDATE_IF_ACTIVE}          false


*** Test Cases ***

Verify IPMI Disable Policy Post BMC Code Update
    [Documentation]  Disable IPMI, update BMC and verify post-update.
    [Tags]  Verify_IPMI_Disable_Policy_Post_BMC_Code_Update
    [Teardown]  Run Keywords  FFDC On Test Case Fail
    ...  AND  Run Inband IPMI Standard Command  lan set 1 access on

    Run Inband IPMI Standard Command  lan set 1 access off
    Run Keyword and Expect Error  *Unable to establish IPMI*
    ...  Run External IPMI Standard Command  lan print

    Upload And Activate Image  ${IMAGE_FILE_PATH}
    ...  skip_if_active=${SKIP_UPDATE_IF_ACTIVE}
    OBMC Reboot (off)
    Verify Running BMC Image  ${IMAGE_FILE_PATH}

    Run Keyword and Expect Error  *Unable to establish IPMI*
    ...  Run External IPMI Standard Command  lan print


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do code update test case setup.

    # Check if image file is provided.
    OperatingSystem.File Should Exist  ${IMAGE_FILE_PATH}

    # - Clean up all existing BMC dumps.
    Run Key  Delete All Dumps  ignore=1
    Run Keyword And Ignore Error  Smart Power Off

