*** Settings ***
Documentation      Keywords for system test.

Library            ../lib/gen_robot_keyword.py
Resource           ../lib/boot_utils.robot
Resource           ../extended/obmc_boot_test_resource.robot
Resource           ../lib/utils.robot
Resource           ../lib/state_manager.robot
Resource           ../lib/rest_client.robot
Resource           resource.txt
Library            OperatingSystem
Library            DateTime

*** Variables ***

${htx_log_dir_path}    ${EXECDIR}${/}logs${/}

# Error strings to check from dmesg.
${ERROR_REGEX}         error|GPU|NVRM|nvidia

# GPU specific error message from dmesg.
${ERROR_DBE_MSG}       (DBE) has been detected on GPU

# Inventory - List of I/O devices to collect for Inventory
@{I/O}                 communication  disk  display  generic  input  multimedia
...                    network  printer  tape

# Inventory Paths of the JSON and YAML files
${json_tmp_file_path}  ${EXECDIR}/inventory_temp_file.json
${yaml_file_path}      ${EXECDIR}/inventory_temp_file.yaml



*** Keywords ***

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

    Ping Host  ${os_host}
    SSHLibrary.Open Connection  ${os_host}  alias=${alias_name}
    Login  ${os_username}  ${os_password}


Tool Exist
    [Documentation]  Check whether given tool is installed on OS.
    [Arguments]  ${tool_name}
    # Description of argument(s):
    # tool_name   Tool name whose existence is to be checked.

    ${output}  ${stderr}  ${rc}=  OS Execute Command  which ${tool_name}
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
    ${out}  ${stderr}  ${rc}=  OS Execute Command  ls ${file_path}
    Log To Console  \n File Exist: ${out}


Is HTX Running
    [Documentation]  Return "True" if the HTX is running, "False"
    ...  otherwise.

    # Example usage:
    #  ${status}=  Is HTX Running
    #  Run Keyword If  '${status}' == 'True'  Shutdown HTX Exerciser

    ${status}  ${stderr}  ${rc}=  OS Execute Command
    ...  htxcmdline -getstats  ignore_err=1
    # Get HTX state
    # (idle, currently running, selected_mdt but not running).
    ${running}=  Set Variable If
    ...  "Currently running" in """${status}"""  ${True}  ${False}

    [Return]  ${running}


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
    ${htx_err}  ${std_err}  ${rc}=  OS Execute Command  cat /tmp/htxerr
    Write Log Data To File
    ...  ${htx_err}  ${htx_log_dir_path}/${OS_HOST}${cur_datetime}.htxerr

    File Exist On OS  /tmp/htxstats
    ${htx_stats}  ${std_err}  ${rc}=  OS Execute Command
    ...  cat /tmp/htxstats
    Write Log Data To File
    ...  ${htx_stats}  ${htx_log_dir_path}/${OS_HOST}_${cur_datetime}.htxstats


REST Upload File To BMC
    [Documentation]  Upload a file via REST to BMC.

    # Generate 32 MB file size
    Run  dd if=/dev/zero of=dummyfile bs=1 count=0 seek=32MB
    OperatingSystem.File Should Exist  dummyfile

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
    ...  msg=Openbmc /upload/image failed.

    # Take SSH connection to BMC and switch to BMC connection to perform
    # the task.
    &{bmc_connection_args}=  Create Dictionary  alias=bmc_connection
    Open Connection And Log In  &{bmc_connection_args}

    # Currently OS SSH session is active, switch to BMC connection.
    Switch Connection  bmc_connection

    # Switch back to OS SSH connection.
    Switch Connection  os_connection


Get CPU Min Frequency Limit
    [Documentation]  Get CPU minimum assignable frequency.

    # lscpu | grep min  returns
    # CPU min MHz:           1983.0000

    ${cmd}=  Catenate  lscpu | grep min  | tr -dc '0-9.\n'
    ${cpu_freq}  ${stderr}  ${rc}=  OS Execute Command  ${cmd}
    [Return]  ${cpu_freq}


Get CPU Min Frequency
    [Documentation]  Get CPU assigned minimum frequency.

    # ppc64_cpu --frequency -t 10  returns
    # min:    3.295 GHz (cpu 143)
    # max:    3.295 GHz (cpu 0)
    # avg:    3.295 GHz

    ${cmd}=  Catenate  ppc64_cpu --frequency -t 10 | grep min
    ...  | cut -f 2 | cut -d ' ' -f 1 | tr -dc '0-9\n'
    ${cpu_freq}  ${stderr}  ${rc}=  OS Execute Command  ${cmd}
    [Return]  ${cpu_freq}


Get CPU Max Frequency Limit
    [Documentation]  Get CPU maximum assignable frequency.

    # lscpu | grep max  returns
    # CPU max MHz:           3300.0000

    ${cmd}=  Catenate  lscpu | grep max  | tr -dc '0-9.\n'
    ${cpu_freq}  ${stderr}  ${rc}=  OS Execute Command  ${cmd}
    [Return]  ${cpu_freq}


Get CPU Max Frequency
    [Documentation]  Get CPU assigned maximum frequency.

    # ppc64_cpu --frequency -t 10  returns
    # min:    3.295 GHz (cpu 143)
    # max:    3.295 GHz (cpu 0)
    # avg:    3.295 GHz

    ${cmd}=  Catenate  ppc64_cpu --frequency -t 10 | grep max
    ...  | cut -f 2 | cut -d ' ' -f 1 | tr -dc '0-9\n'
    ${cpu_freq}  ${stderr}  ${rc}=  OS Execute Command  ${cmd}
    [Return]  ${cpu_freq}


Get CPU Max Temperature
    [Documentation]  Get the highest CPU Temperature.

    ${temperature_objs}=  Read Properties
    ...  ${SENSORS_URI}temperature/enumerate
    # Filter the dictionary to get just the CPU temperature info.
    ${cmd}=  Catenate  {k:v for k,v in $temperature_objs.iteritems()
    ...  if re.match('${SENSORS_URI}temperature/p.*core.*temp', k)}
    ${cpu_temperatuture_objs}  Evaluate  ${cmd}  modules=re
    # Create a list of the CPU temperature values (current).
    ${cpu_temperatures}=  Evaluate
    ...  [ x['Value'] for x in $cpu_temperatuture_objs.values() ]

    ${cpu_max_temp}  Evaluate  max(map(int, $cpu_temperatures))/1000
    [Return]  ${cpu_max_temp}


Get CPU Min Temperature
    [Documentation]  Get the  CPU Temperature.

    ${temperature_objs}=  Read Properties
    ...  ${SENSORS_URI}temperature/enumerate
    # Filter the dictionary to get just the CPU temperature info.
    ${cmd}=  Catenate  {k:v for k,v in $temperature_objs.iteritems()
    ...  if re.match('${SENSORS_URI}temperature/p.*core.*temp', k)}
    ${cpu_temperatuture_objs}=  Evaluate  ${cmd}  modules=re
    # Create a list of the CPU temperature values (current).
    ${cpu_temperatures}=  Evaluate
    ...  [ x['Value'] for x in $cpu_temperatuture_objs.values() ]

    ${cpu_min_temp}  Evaluate  min(map(int, $cpu_temperatures))/1000
    [Return]  ${cpu_min_temp}


Check For Errors On OS Dmesg Log
    [Documentation]  Check if dmesg has nvidia errors logged.

    ${dmesg_log}  ${stderr}  ${rc}=  OS Execute Command
    ...  dmesg | egrep '${ERROR_REGEX}'
    # To enable multiple string check.
    Should Not Contain  ${dmesg_log}  ${ERROR_DBE_MSG}
    ...  msg=OS dmesg shows ${ERROR_DBE_MSG}.


Collect NVIDIA Log File
    [Documentation]  Collect ndivia-smi command output.
    [Arguments]  ${suffix}
    # Description of argument(s):
    # suffix     String name to append.

    # Collects the output of ndivia-smi cmd output.
    # +--------------------------------------------------------------------+
    # | NVIDIA-SMI 361.89                 Driver Version: 361.89           |
    # |-------------------------------+----------------------+-------------+
    # | GPU  Name        Persistence-M| Bus-Id        Disp.A | GPU     ECC |
    # | Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | Utiliz  err |
    # |===============================+======================+=============|
    # |   0  Tesla P100-SXM2...  On   | 0002:01:00.0     Off |           0 |
    # | N/A   25C    P0    35W / 300W |    931MiB / 16280MiB | 0%  Default |
    # +-------------------------------+----------------------+-------------+
    # |   1  Tesla P100-SXM2...  On   | 0003:01:00.0     Off |           0 |
    # | N/A   26C    P0    40W / 300W |   1477MiB / 16280MiB | 0%  Default |
    # +-------------------------------+----------------------+-------------+
    # |   2  Tesla P100-SXM2...  On   | 0006:01:00.0     Off |           0 |
    # | N/A   25C    P0    35W / 300W |    931MiB / 16280MiB | 0%  Default |
    # +-------------------------------+----------------------+-------------+
    # |   3  Tesla P100-SXM2...  On   | 0007:01:00.0     Off |           0 |
    # | N/A   44C    P0   290W / 300W |    965MiB / 16280MiB | 0%  Default |
    # +-------------------------------+----------------------+-------------+
    # +--------------------------------------------------------------------+
    # | Processes:                                              GPU Memory |
    # |  GPU       PID  Type  Process name                      Usage      |
    # |====================================================================|
    # |    0     28459    C   hxenvidia                             929MiB |
    # |    1     28460    C   hxenvidia                            1475MiB |
    # |    2     28461    C   hxenvidia                             929MiB |
    # |    3     28462    C   hxenvidia                             963MiB |
    # +--------------------------------------------------------------------+

    # Create logs directory and get current datetime.
    Create Directory  ${htx_log_dir_path}
    ${cur_datetime}=  Get Current Date  result_format=%Y%m%d%H%M%S%f

    ${nvidia_out}  ${stderr}  ${rc}=  OS Execute Command  nvidia-smi
    Write Log Data To File
    ...  ${nvidia_out}
    ...  ${htx_log_dir_path}/${OS_HOST}_${cur_datetime}.nvidia_${suffix}


Get GPU Power Limit
    [Documentation]  Get NVIDIA GPU maximum permitted power draw.

    # nvidia-smi --query-gpu=power.limit --format=csv returns
    # power.limit [W]
    # 300.00 W
    # 300.00 W
    # 300.00 W
    # 300.00 W

    ${cmd}=  Catenate  nvidia-smi --query-gpu=power.limit
    ...  --format=csv | cut -f 1 -d ' ' | sort -n -u | tail -n 1
    ${nvidia_out}  ${stderr}  ${rc}=  OS Execute Command  ${cmd}
    # Allow for sensor overshoot.  That is, max power reported for
    # a GPU could be a few watts above the limit.
    ${power_max}=  Evaluate  ${nvidia_out}+${7.00}
    [Return]  ${power_max}


Get GPU Max Power
    [Documentation]  Get the maximum GPU power dissipation.

    # nvidia-smi --query-gpu=power.draw --format=csv returns
    # power.draw [W]
    # 34.12 W
    # 34.40 W
    # 36.55 W
    # 36.05 W

    ${cmd}=  Catenate  nvidia-smi --query-gpu=power.draw
    ...  --format=csv | cut -f 1 -d ' ' | sort -n -u | tail -n 1
    ${nvidia_out}  ${stderr}  ${rc}=  OS Execute Command  ${cmd}
    [Return]  ${nvidia_out}


Get GPU Min Power
    [Documentation]  Return the minimum GPU power value as record by
    ...  nvidia-smi.

    ${cmd}=  Catenate  nvidia-smi --query-gpu=power.draw --format=csv |
    ...  grep -v 'power.draw' | cut -f 1 -d ' ' | sort -n -u | head -1
    ${gpu_min_power}  ${stderr}  ${rc}=  OS Execute Command  ${cmd}
    [Return]  ${gpu_min_power}


Get GPU Temperature Limit
    [Documentation]  Get NVIDIA GPU maximum permitted temperature.

    # nvidia-smi -q -d TEMPERATURE  | grep "GPU Max" returns
    #    GPU Max Operating Temp      : 83 C
    #    GPU Max Operating Temp      : 83 C
    #    GPU Max Operating Temp      : 83 C
    #    GPU Max Operating Temp      : 83 C

    ${cmd}=  Catenate  nvidia-smi -q -d TEMPERATURE  | grep "GPU Max"
    ...  | cut -f 2 -d ":" |  tr -dc '0-9\n' | sort -n -u | tail -n 1
    ${nvidia_out}  ${stderr}  ${rc}=  OS Execute Command  ${cmd}
    [Return]  ${nvidia_out}


Get GPU Min Temperature
    [Documentation]  Get the minimum GPU temperature.

    ${cmd}=  Catenate  nvidia-smi --query-gpu=temperature.gpu
    ...  --format=csv | grep -v 'temperature.gpu' | sort -n -u | head -1
    ${nvidia_out}  ${stderr}  ${rc}=  OS Execute Command  ${cmd}
    [Return]  ${nvidia_out}


Get GPU Max Temperature
    [Documentation]  Get the maximum GPU temperature.

    # nvidia-smi --query-gpu=temperature.gpu --format=csv returns
    # 38
    # 41
    # 38
    # 40

    ${cmd}=  Catenate  nvidia-smi --query-gpu=temperature.gpu
    ...  --format=csv | sort -n -u | tail -n 1
    ${nvidia_out}  ${stderr}  ${rc}=  OS Execute Command  ${cmd}
    [Return]  ${nvidia_out}


Get GPU Temperature Via REST
    [Documentation]  Return the temperature in degrees C of the warmest GPU
    ...  as reportd by REST.

    # NOTE: This endpoint path is not defined until system has been powered-on.
    ${temperature_objs}=  Read Properties  ${SENSORS_URI}temperature/enumerate
    ...  timeout=30  quiet=1

    ${core_temperatures_list}=  Catenate  {k:v for k,v in $temperature_objs.iteritems()
    ...  if re.match('${SENSORS_URI}temperature/.*_core_temp', k)}
    ${gpu_temperature_objs_dict}=  Evaluate  ${core_temperatures_list}  modules=re

    # Create a list containing all of the GPU temperatures.
    ${gpu_temperatures}=  Evaluate
    ...  [ x['Value'] for x in $gpu_temperature_objs_dict.values() ]

    # Find the max temperature value and divide by 1000 to get just the integer
    # portion.
    ${max_gpu_temperature}=  Evaluate  max(map(int, $gpu_temperatures))/1000

    [Return]  ${max_gpu_temperature}


Get GPU Clock Limit
    [Documentation]  Get NVIDIA GPU maximum permitted graphics clock.

    # nvidia-smi --query-gpu=clocks.max.gr --format=csv  returns
    # 1530 MHz
    # 1530 MHz
    # 1530 MHz
    # 1530 MHz

    ${cmd}=  Catenate  nvidia-smi --query-gpu=clocks.max.gr
    ...  --format=csv | cut -f 1 -d ' ' |  sort -n -u | tail -n 1
    ${nvidia_out}  ${stderr}  ${rc}=  OS Execute Command  ${cmd}
    [Return]  ${nvidia_out}


Get GPU Clock
    [Documentation]  Get the highest assigned value of the GPU graphics clock.

    # nvidia-smi --query-gpu=clocks.gr --format=csv  returns
    # 1230 MHz
    # 1230 MHz
    # 135 MHz
    # 150 MHz

    ${cmd}=  Catenate  nvidia-smi --query-gpu=clocks.gr
    ...  --format=csv | cut -f 1 -d ' ' | sort -n -u | tail -n 1
    ${nvidia_out}  ${stderr}  ${rc}=  OS Execute Command  ${cmd}
    [Return]  ${nvidia_out}


Count GPUs From BMC
    [Documentation]  Determine number of GPUs from the BMC.  Hostboot
    ...  needs to have been run previously because the BMC gets GPU data
    ...  from Hostboot.

    # Example of gv* endpoint data:
    # "/xyz/openbmc_project/inventory/system/chassis/motherboard/gv100card0": {
    #     "Functional": 1,
    #     "Present": 1,
    #     "PrettyName": ""
    # },

    ${num_bmc_gpus}=  Set Variable  ${0}

    ${gpu_list}=  Get Endpoint Paths
    ...  ${HOST_INVENTORY_URI}system/chassis/motherboard  gv*

    :FOR  ${gpu_uri}  IN  @{gpu_list}
    \  ${present}=  Read Attribute  ${gpu_uri}  Present
    \  ${state}=  Read Attribute  ${gpu_uri}  Functional
    \  Rpvars  gpu_uri  present  state
    \  ${num_bmc_gpus}=  Run Keyword If  ${present} and ${state}
    ...  Evaluate  ${num_bmc_gpus}+${1}
    [Return]  ${num_bmc_gpus}


Create Default MDT Profile
    [Documentation]  Create default mdt.bu profile and run.

    Rprint Timen  Create HTX mdt profile.

    ${profile}  ${stderr}  ${rc}=  OS Execute Command
    ...  htxcmdline -createmdt
    Rprintn  ${profile}
    Should Contain  ${profile}  mdts are created successfully
    ...  msg=Create MDT profile failed. response=${profile}


Run MDT Profile
    [Documentation]  Load user pre-defined MDT profile.
    [Arguments]  ${HTX_MDT_PROFILE}=${HTX_MDT_PROFILE}
    # Description of argument(s):
    # HTX_MDT_PROFILE  MDT profile to be executed (e.g. "mdt.bu").

    Rprint Timen  Start HTX mdt profile execution.
    ${htx_run}  ${stderr}  ${rc}=  OS Execute Command
    ...  htxcmdline -run -mdt ${HTX_MDT_PROFILE}
    Rprintn  ${htx_run}
    Should Contain  ${htx_run}  Activated
    ...  msg=htxcmdline run mdt did not return "Activated" status.


Check HTX Run Status
    [Documentation]  Get HTX exerciser status and check for error.
    [Arguments]  ${sleep_time}=0

    # Description of argument(s):
    # sleep_time  The amount of time to sleep after checking status.

    Rprint Timen  Check HTX mdt Status and error.
    ${htx_status}  ${stderr}  ${rc}=  OS Execute Command
    ...  htxcmdline -status -mdt ${HTX_MDT_PROFILE}
    Rprintn  ${htx_status}

    ${htx_errlog}  ${stderr}  ${rc}=  OS Execute Command
    ...  htxcmdline -geterrlog
    Rprintn  ${htx_errlog}

    Should Contain  ${htx_errlog}  file </tmp/htxerr> is empty
    ...  msg=HTX geterrorlog was not empty.

    Return From Keyword If  "${sleep_time}" == "0"

    Run Key U  Sleep \ ${sleep_time}


Shutdown HTX Exerciser
    [Documentation]  Shut down HTX exerciser run.

    Rprint Timen  Shutdown HTX Run
    ${shutdown}  ${stderr}  ${rc}=  OS Execute Command
    ...  htxcmdline -shutdown -mdt ${HTX_MDT_PROFILE}
    Rprintn  ${shutdown}

    ${match_count_no_mdt}=  Count Values In List  ${shutdown}
    ...  No MDT is currently running
    ${match_count_success}=  Count Values In List  ${shutdown}
    ...  shutdown successfully
    Run Keyword If  ${match_count_no_mdt} == 0 and ${match_count_success} == 0
    ...  Fail  msg=Shutdown command returned unexpected message.


Create JSON Inventory File
    [Documentation]  Create a JSON inventory file, and make a YAML copy.
    [Arguments]  ${json_file_path}
    # Description of argument:
    # json_file_path  Where the inventory file is wrtten to.

    Login To OS
    Compile Inventory JSON
    Run  json2yaml ${json_tmp_file_path} ${yaml_file_path}
    # Format to JSON pretty print to file.
    Run  python -m json.tool ${json_tmp_file_path} > ${json_file_path}
    OperatingSystem.File Should Exist  ${json_file_path}
    ...  msg=File ${json_file_path} does not exist.


Compile Inventory JSON
    [Documentation]  Compile the Inventory into a JSON file.
    Create File  ${json_tmp_file_path}
    Write New JSON List  ${json_tmp_file_path}  Inventory
    Retrieve HW Info And Write  processor  ${json_tmp_file_path}
    Retrieve HW Info And Write  memory  ${json_tmp_file_path}
    Retrieve HW Info And Write List  ${I/O}  ${json_tmp_file_path}  I/O  last
    Close New JSON List  ${json_tmp_file_path}


Write New JSON List
    [Documentation]  Start a new JSON list element in file.
    [Arguments]  ${json_tmp_file_path}  ${json_field_name}
    # Description of argument(s):
    # json_tmp_file_path   Name of file to write to.
    # json_field_name      Name to give json list element.
    Append to File  ${json_tmp_file_path}  { "${json_field_name}" : [


Close New JSON List
    [Documentation]  Close JSON list element in file.
    [Arguments]  ${json_tmp_file_path}
    # Description of argument(s):
    # json_tmp_file_path  Path of file to write to.
    Append to File  ${json_tmp_file_path}  ]}


Retrieve HW Info And Write
    [Documentation]  Retrieve and write info, add a comma if not last item.
    [Arguments]  ${class}  ${json_tmp_file_path}  ${last}=false
    # Description of argument(s):
    # class               Device class to retrieve with lshw.
    # json_tmp_file_path  Path of file to write to.
    # last                Is this the last element in the parent JSON?
    Write New JSON List  ${json_tmp_file_path}  ${class}
    ${output} =  Retrieve Hardware Info  ${class}
    ${output} =  Clean Up String  ${output}
    Run Keyword if  ${output.__class__ is not type(None)}
    ...  Append To File  ${json_tmp_file_path}  ${output}
    Close New JSON List  ${json_tmp_file_path}
    Run Keyword if  '${last}' == 'false'
    ...  Append to File  ${json_tmp_file_path}  ,


Retrieve HW Info And Write List
    [Documentation]  Does a Retrieve/Write with a list of classes and
    ...              encapsulates them into one large JSON element.
    [Arguments]  ${list}  ${json_tmp_file_path}  ${json_field_name}
    ...          ${last}=false
    # Description of argument(s):
    # list                 The list of devices classes to retrieve with lshw.
    # json_tmp_file_path   Path of file to write to.
    # json_field_name      Name of the JSON element to encapsulate this list.
    # last                 Is this the last element in the parent JSON?
    Write New JSON List  ${json_tmp_file_path}  ${json_field_name}
    : FOR  ${class}  IN  @{list}
    \  ${tail}  Get From List  ${list}  -1
    \  Run Keyword if  '${tail}' == '${class}'
    \  ...  Retrieve HW Info And Write  ${class}  ${json_tmp_file_path}  true
    \  ...  ELSE  Retrieve HW Info And Write  ${class}  ${json_tmp_file_path}
    Close New JSON List  ${json_tmp_file_path}
    Run Keyword if  '${last}' == 'false'
    ...  Append to File  ${json_tmp_file_path}  ,


Retrieve Hardware Info
    [Documentation]  Retrieves the lshw output of the device class as JSON.
    [Arguments]  ${class}
    # Description of argument(s):
    # class  Device class to retrieve with lshw.
    ${output}  ${stderr}  ${rc}=  OS Execute Command  lshw -c ${class} -json
    ${output} =  Verify JSON string  ${output}
    [Return]  ${output}


Verify JSON String
    [Documentation]  Ensure the JSON string content is separated by commas.
    [Arguments]  ${unver_string}
    # Description of argument(s):
    # unver_string  JSON String we will be checking for lshw comma errors.
    ${unver_string} =  Convert to String  ${unver_string}
    ${ver_string} =  Replace String Using Regexp  ${unver_string}  }\\s*{  },{
    [Return]  ${ver_string}


Clean Up String
    [Documentation]  Remove extra whitespace and trailing commas.
    [Arguments]  ${dirty_string}
    # Description of argument(s):
    # dirty_string  String that will be space stripped and have comma removed.
    ${clean_string} =  Strip String  ${dirty_string}
    ${last_char} =  Get Substring  ${clean_string}  -1
    ${trimmed_string} =  Get Substring  ${clean_string}  0  -1
    ${clean_string} =  Set Variable If  '${last_char}' == ','
    ...  ${trimmed_string}  ${clean_string}
    [Return]  ${clean_string}


Get OS Network Interface Names
    [Documentation]  Return a list of interface names on the OS.

    ${stdout}  ${stderr}  ${rc}=  OS Execute Command  ls /sys/class/net
    @{interface_names}=  Split String  ${stdout}
    [Return]  @{interface_names}


Run Soft Bootme
    [Documentation]  Run a soft bootme for a period of an hour.
    [Arguments]  ${bootme_period}=3
    # Description of argument(s):
    # bootme_time     Bootme period to be rebooting the system.

    ${output}  ${stderr}  ${rc}=  OS Execute Command
    ...  htxcmdline -bootme on mode:soft period:${bootme_period}
    Should Contain  ${output}  bootme on is completed successfully


Shutdown Bootme
    [Documentation]  Stop the bootme process.

    ${output}  ${stderr}  ${rc}=  OS Execute Command  htxcmdline -bootme off
    Should Contain  ${output}  bootme off is completed successfully
