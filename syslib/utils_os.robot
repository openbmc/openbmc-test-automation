*** Settings ***
Documentation      Keywords for system related test. This is a subset of the
...                utils.robot. This resource file keywords  is specifically
...                define for system test use cases.

Library            ../lib/gen_robot_keyword.py
Resource           ../extended/obmc_boot_test_resource.robot
Resource           ../lib/utils.robot
Resource           ../lib/state_manager.robot

*** Variables ***

# Error strings to check from dmesg.
${ERROR_REGEX}     error|GPU|NVRM|nvidia

# GPU specific error message from dmesg.
${ERROR_DBE_MSG}   (DBE) has been detected on GPU

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


Check For Errors On OS Dmesg Log
    [Documentation]  Check if dmesg has nvidia errors logged.

    ${dmesg_log}=  Execute Command On OS  dmesg | egrep '${ERROR_REGEX}'
    # To enable multiple string check.
    Should Not Contain Any  ${dmesg_log}  ${ERROR_DBE_MSG}


Collect NVIDIA Log File
    [Documentation]  Collect ndivia-smi command output.

    # Collects the output of ndivia-smi cmd output.
    # TODO: GPU current temperature threshold check.
    #       openbmc/openbmc-test-automation#637
    # +-----------------------------------------------------------------------------+
    # | NVIDIA-SMI 361.89                 Driver Version: 361.89                    |
    # |-------------------------------+----------------------+----------------------+
    # | GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
    # | Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
    # |===============================+======================+======================|
    # |   0  Tesla P100-SXM2...  On   | 0002:01:00.0     Off |                    0 |
    # | N/A   25C    P0    35W / 300W |    931MiB / 16280MiB |      0%      Default |
    # +-------------------------------+----------------------+----------------------+
    # |   1  Tesla P100-SXM2...  On   | 0003:01:00.0     Off |                    0 |
    # | N/A   26C    P0    40W / 300W |   1477MiB / 16280MiB |      0%      Default |
    # +-------------------------------+----------------------+----------------------+
    # |   2  Tesla P100-SXM2...  On   | 0006:01:00.0     Off |                    0 |
    # | N/A   25C    P0    35W / 300W |    931MiB / 16280MiB |      0%      Default |
    # +-------------------------------+----------------------+----------------------+
    # |   3  Tesla P100-SXM2...  On   | 0007:01:00.0     Off |                    0 |
    # | N/A   44C    P0   290W / 300W |    965MiB / 16280MiB |     99%      Default |
    # +-------------------------------+----------------------+----------------------+
    # +-----------------------------------------------------------------------------+
    # | Processes:                                                       GPU Memory |
    # |  GPU       PID  Type  Process name                               Usage      |
    # |=============================================================================|
    # |    0     28459    C   hxenvidia                                      929MiB |
    # |    1     28460    C   hxenvidia                                     1475MiB |
    # |    2     28461    C   hxenvidia                                      929MiB |
    # |    3     28462    C   hxenvidia                                      963MiB |
    # +-----------------------------------------------------------------------------+

    # Create logs directory and get current datetime.
    Create Directory  ${htx_log_dir_path}
    ${cur_datetime}=  Get Current Date  result_format=%Y%m%d%H%M%S%f

    ${nvidia_out}=  Execute Command On BMC  nvidia-smi
    Write Log Data To File
    ...  ${nvidia_out}  ${htx_log_dir_path}/${OS_HOST}_${cur_datetime}.nvidia
