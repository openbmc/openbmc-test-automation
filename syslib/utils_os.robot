*** Settings ***
Documentation      Keywords for system related test. This is a subset of the
...                utils.robot. This resource file keywords  is specifically
...                define for system test use cases.

Library            ../lib/gen_robot_keyword.py
Resource           ../extended/obmc_boot_test_resource.robot
Resource           ../lib/utils.robot
Resource           ../lib/state_manager.robot
Resource           resource.txt

*** Variables ***

*** Keywords ***

Execute Command On OS
    [Documentation]  Execute given command on OS and return output.
    [Arguments]  ${command}
    # Description of argument(s):
    # command  Shell command to be executed on OS.
    ${stdout}  ${stderr}=  Execute Command  ${command}  return_stderr=True
    Should Be Empty  ${stderr}
    [Return]  ${stdout}


Login To OS
    [Documentation]  Login to OS Host.
    [Arguments]  ${os_host}=${OS_HOST}  ${os_username}=${OS_USERNAME}
    ...          ${os_password}=${OS_PASSWORD}
    # Description of argument(s):
    # os_host      IP address of the OS Host.
    # os_username  OS Host Login user name.
    # os_password  OS Host Login passwrd.

    Ping Host  ${os_host}
    Open Connection  ${os_host}
    Login  ${os_username}  ${os_password}


Tool Exist
    [Documentation]  Check whether given tool is installed on OS.
    [Arguments]  ${tool_name}
    # Description of argument(s):
    # tool_name   Tool name whose existence is to be checked.
    Login To OS
    ${output}=  Execute Command On OS  which ${tool_name}
    Should Contain  ${output}  ${tool_name}
    ...  msg=Please install ${tool_name} tool.


Boot To OS
    [Documentation]  Boot host OS.
    Run Key  OBMC Boot Test \ REST Power On


Power Off Host
    [Documentation]  Power off host.
    Run Key  OBMC Boot Test \ REST Power Off


File Exist On OS
    [Documentation]  Check if the given file path exist on OS.
    [Arguments]  ${file_path}
    # Description of argument(s):
    # file_path   Absolute file path.

    Login To OS
    ${out}=  Execute Command On OS  ls ${file_path}
    Log To Console  \n File Exist: ${out}


Is HTX Running
    [Documentation]  Check if the HTX exerciser is currently running.

    ${status}=  Execute Command On OS  htxcmdline -status
    Should Not Contain  ${status}  Daemon state is <IDLE>


Pre Test Case Execution
    [Documentation]  Do the initial test setup.
    # 1. Check if HTX tool exist.
    # 2. Power on

    Boot To OS
    HTX Tool Exist

    # Shutdown if HTX is running.
    ${status}=  Run Keyword And Return Status  Is HTX Running
    Run Keyword If  '${status}' == 'True'
    ...  Shutdown HTX Exerciser


Create Default MDT Profile
    [Documentation]  Create default mdt.bu profile and run.

    Rprint Timen  Create HTX mdt profile.

    ${profile}=  Execute Command On OS  htxcmdline -createmdt
    Rprintn  ${profile}
    Should Contain  ${profile}  mdts are created successfully


Run MDT Profile
    [Documentation]  Load user pre-defined MDT profile.

    Rprint Timen  Start HTX mdt profile execution.
    ${htx_run}=  Execute Command On OS
    ...  htxcmdline -run -mdt ${HTX_MDT_PROFILE}
    Rprintn  ${htx_run}
    Should Contain  ${htx_run}  Activated


Check HTX Run Status
    [Documentation]  Get HTX exerciser status and check for error.

    Rprint Timen  Check HTX mdt Status and error.
    ${status}=  Execute Command On OS
    ...  htxcmdline -status -mdt ${HTX_MDT_PROFILE}
    Rprintn  ${status}

    ${errlog}=  Execute Command On OS  htxcmdline -geterrlog
    Rprintn  ${errlog}

    Should Contain  ${errlog}  file </tmp/htxerr> is empty


Shutdown HTX Exerciser
    [Documentation]  Shut down HTX exerciser run.

    Rprint Timen  Shutdown HTX Run
    ${shutdown}=  Execute Command On OS
    ...  htxcmdline -shutdown -mdt ${HTX_MDT_PROFILE}
    Rprintn  ${shutdown}
    Should Contain  ${shutdown}  shutdown successfully

