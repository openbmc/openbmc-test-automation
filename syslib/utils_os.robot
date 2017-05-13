*** Settings ***
Documentation      Keywords for system related test. This is a subset of the
...                utils.robot. This resource file keywords  is specifically
...                define for system test use cases.

Library            ../lib/gen_robot_keyword.py
Resource           ../extended/obmc_boot_test_resource.robot
Resource           ../lib/utils.robot
Resource           ../lib/state_manager.robot

Library            OperatingSystem
Library            DateTime

*** Variables ***

${HTX_LOG_PATH}   ${EXECDIR}${/}logs${/}


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


HTX Tool Exist
    [Documentation]  Check whether HTX exerciser is installed on OS.
    Login To OS
    ${output}=  Execute Command On OS  which htxcmdline
    Should Contain  ${output}  htxcmdline
    ...  msg=Please install HTX exerciser.


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


Write Log Data To File
    [Documentation]  Write log data to the logs directory.
    [Arguments]  ${data}=      ${log_file_path}=
    # Description of argument(s):
    # data            String buffer.
    # log_file_path   Absoulte file path.

    Create File  ${log_file_path}  ${data}


Collect HTX Log Files
    [Documentation]  Collect status and error log files.
    # Collects the following files:
    # HTX error log file /tmp/htxerr
    # HTX status log file /tmp/htxstats

    # Create logs directory and get current datetime.
    Create Directory  ${HTX_LOG_PATH}
    ${cur_datetime}=  Get Current Date  result_format=%Y%m%d%H%M%S%f

    File Exist On OS  /tmp/htxerr
    ${htx_err}=  Execute Command On BMC  cat /tmp/htxerr
    Write Log Data To File  ${htx_err}  ${HTX_LOG_PATH}/htxerr_${cur_datetime}

    File Exist On OS  /tmp/htxstats
    ${htx_err}=  Execute Command On BMC  cat /tmp/htxerr
    Write Log Data To File
    ...  ${htx_err}  ${HTX_LOG_PATH}/htxstats_${cur_datetime}

