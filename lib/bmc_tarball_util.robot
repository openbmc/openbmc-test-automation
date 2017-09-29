*** Settings ***
Documentation   BMC tarball utilities keywords.

Resource        utils.robot

*** Variables ***

${pdbg_install_path}   /tmp/tarball/bin/

*** Keywords ***

Execute PDBG Command On BMC
    [Documentation]  Execute pdbg command on BMC.
    [Arguments]  ${cmd}

    # Description of argument(s):
    # cmd     Command string which needs to be executed.

    ${stdout}  ${stderr}=  BMC Execute Command
    ...  ${pdbg_install_path}${cmd}  return_stderr=True
    Should Be Empty  ${stderr}
    Should Not Be Empty  ${stdout}
    [Return]  ${stdout}


Check And Install PDBG Binary
    [Documentation]  Check and install pdbg on BMC.

    ${bin_exist}=  Check If PDBG Binary Exist
    Return From Keyword If  '${bin_exist}' = '${True}'  ${True}
    Return From Keyword If  '${DEBUG_TARBALL_PATH}' == '${EMPTY}'  ${False}
    Install Debug Tarball On BMC  ${DEBUG_TARBALL_PATH}


Check If PDBG Binary Exist
    [Documentation]  Check if pdbg binary installed on BMC.

    ${stdout}  ${stderr}=  BMC Execute Command
    ...  which ${pdbg_install_path}pdbg  return_stderr=True
    Should Be Empty  ${stderr}
    Should Not Be Empty  ${stdout}

