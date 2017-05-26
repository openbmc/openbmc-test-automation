*** Settings ***
Documentation      Keywords for system related test. This is a subset of the
...                utils.robot. This resource file keywords  is specifically
...                define for system test use cases.

Library            ../lib/gen_robot_keyword.py
Library            OperatingSystem
Resource           ../extended/obmc_boot_test_resource.robot
Resource           ../lib/utils.robot
Resource           ../lib/state_manager.robot
Resource           ../lib/rest_client.robot

Library            OperatingSystem
Library            DateTime

*** Variables ***

${htx_log_dir_path}   ${EXECDIR}${/}logs${/}


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
    ...          ${alias_name}=os_connection
    # Description of argument(s):
    # os_host      IP address of the OS Host.
    # os_username  OS Host Login user name.
    # os_password  OS Host Login passwrd.
    # alias_name   Default OS SSH session connection alias name.
    # TODO: Generalize alias naming using openbmc/openbmc-test-automation#633

    Ping Host  ${os_host}
    Open Connection  ${os_host}  alias=${alias_name}
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


Write Log Data To File
    [Documentation]  Write log data to the logs directory.
    [Arguments]  ${data}=  ${log_file_path}=
    # Description of argument(s):
    # data            String buffer.
    # log_file_path   The log file path.

    Create File  ${log_file_path}  ${data}


Collect HTX Log Files
    [Documentation]  Collect status and error log files.
    # Collects the following files:
    # HTX error log file /tmp/htxerr
    # HTX status log file /tmp/htxstats

    # Create logs directory and get current datetime.
    Create Directory  ${htx_log_dir_path}
    ${cur_datetime}=  Get Current Date  result_format=%Y%m%d%H%M%S%f

    File Exist On OS  /tmp/htxerr
    ${htx_err}=  Execute Command On BMC  cat /tmp/htxerr
    Write Log Data To File
    ...  ${htx_err}  ${htx_log_dir_path}/${OS_HOST}${cur_datetime}.htxerr

    File Exist On OS  /tmp/htxstats
    ${htx_stats}=  Execute Command On BMC  cat /tmp/htxstats
    Write Log Data To File
    ...  ${htx_stats}  ${htx_log_dir_path}/${OS_HOST}_${cur_datetime}.htxstats


REST Upload File To BMC
    [Documentation]  Upload a file via REST to BMC.

    # Generate 32 MB file size
    Run  dd if=/dev/zero of=dummyfile bs=1 count=0 seek=32MB
    OperatingSystem.File Should Exist  dummyfile

    # Take SSH connection to BMC and switch to BMC connection to perform
    # the task.
    &{bmc_connection_args}=  Create Dictionary  alias=bmc_connection
    Open Connection And Log In  &{bmc_connection_args}

    # Currently OS SSH session is active, switch to BMC connection.
    # Delete /tmp/images directory to disable image verification.
    # Post test completion, reboot the BMC to re-activate.
    Switch Connection  bmc_connection
    Execute Command On BMC  rm -rf /tmp/images/

    # Get the content of the file and upload to BMC
    ${image_data}=  OperatingSystem.Get Binary File  dummyfile

    # Get REST session to BMC
    Initialize OpenBMC

    # Create the REST payload headers and data
    ${data}=  Create Dictionary  data  ${image_data}
    ${headers}=  Create Dictionary  Content-Type=application/octet-stream
    ...  Accept=application/octet-stream
    Set To Dictionary  ${data}  headers  ${headers}

    ${resp}=  Post Request  openbmc  /upload/image  &{data}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}

    # Delete uploaded image file.
    # TODO: Delete via REST openbmc/openbmc#1550
    Execute Command On BMC  rm -f /tmp/images/*

    # Switch back to OS SSH connection.
    Switch Connection  os_connection


Trigger BMC Reset via Reboot
    [Documentation]    Execute reboot command on the remote BMC and
    ...                returns immediately. This keyword "Start Command"
    ...                returns nothing and does not wait for the command
    ...                execution to be finished.
    Open Connection And Log In

    Start Command   /sbin/reboot

