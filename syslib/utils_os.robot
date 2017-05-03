*** Settings ***
Documentation      Keywords for system related test. This is a subset of the
...                utils.robot. This resource file keywords  is specifically
...                define for system test use cases.

Resource           ../lib/utils.robot
Resource           ../lib/state_manager.robot

*** Variables ***

*** Keywords ***

Execute Command On OS
    [Documentation]  Execute given command on OS and return output.
    [Arguments]  ${command}
    # Desription of argument(s):
    # ${command}  Shell command to be executed on OS.
    ${stdout}  ${stderr}=  Execute Command  ${command}  return_stderr=True
    Should Be Empty  ${stderr}
    [Return]  ${stdout}


Login To OS
    [Documentation]  Login to OS Host.
    [Arguments]  ${os_host}=${OS_HOST}  ${os_username}=${OS_USERNAME}
    ...          ${os_password}=${OS_PASSWORD}
    # Desription of argument(s):
    # ${os_host} IP address of the OS Host.
    # ${os_username}  OS Host Login user name.
    # ${os_password}  OS Host Login passwrd.

    Ping Host  ${os_host}
    Open Connection  ${os_host}
    Login  ${os_username}  ${os_password}


HTX Tool Exist
    [Documentation]  Check If HTX exerciser is installed on OS.
    Login To OS
    ${output}=  Execute Command On OS  which htxcmdline
    Should Contain  ${output}  htxcmdline
    ...  msg=Please install HTX exerciser.


Boot To OS
    [Documentation]  Boot host OS.
    Initiate Host Boot
    Wait Until Keyword Succeeds
    ...  10 min  10 sec  Is OS Starting
    Wait for OS
