*** Settings ***
Documentation     Test System Dump

Resource         ../lib/bmc_network_utils.robot
Resource         ../lib/resource.robot
Resource         ../lib/openbmc_ffdc.robot
Resource         ../lib/bmc_redfish_utils.robot
Resource         ../lib/bmc_redfish_resource.robot
Resource         ../lib/boot_utils.robot
Resource         ../lib/logging_utils.robot
Library          String
Library          SSHLibrary
Library          ../lib/pel_utils.py
Library          ../lib/gen_robot_valid.py
Library          ../lib/external_intf/hmc_utils.py  ${OPENBMC_HOST}  ${HMC_IP_1}
...              ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}  WITH NAME  Hmc1



Suite Setup         Suite Setup Execution
Suite Teardown      Suite Teardown Execution
Test Setup          Test Setup Execution
Test Teardown       Test Teardown Execution

*** Test Cases ***

Trigger MPIPL From BMC CLI And Verify System Dump
    [Documentation]  Expect System dump on user initiated MPIPL from BMC CLI
    [Tags]  Trigger_MPIPL_From_BMC_CLI_And_Verify_System_Dump


        # Initiating MPIPL
        Tool Initd MP Reboot
        ${dump_count} =  Check For System Dump
        Log To Console  Dump Count: ${dump_count}

        # Check for dump generated in PHYP
        ${phyp_dump} =  Run Keyword If  ${dump_count} == 1  Run Keyword  Execute Phyp Command  dump -q
        ...     ELSE  Log To Console  "Dump not generated"

        # Parse only System Dump output from dump -q
        ${phyp_dump}=  Fetch From Left  ${phyp_dump}  Hardware Unit Dump:
        ${line} =  Get Lines Containing String  ${phyp_dump}  File name:
        @{file_name_line} =  Split String  ${line}  :
        ${file_name} =  Strip String  @{file_name_line}[1]  mode=both
        Log To Console  Sys Dump File generated: ${file_name}

        # Verify offloaded dump size in HMC
        #${dump_size} =   Hmc1.Verify System Dump Offload
        #Log To Console  Dump size:  ${dump_size}

        ${errors} =  Peltool  -l
        Log To Console  ${errors}


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do suite setup tasks.

    Redfish.Login
    Redfish Power On

    # Clean up existing connections.
    ${stdout}  ${stderr}  ${rc} =  Hmc1.Disconnect Cec
    Sleep  10s

    # Connect CEC to HMCs.
    ${stdout}  ${stderr}  ${rc} =  Hmc1.Connect Cec
    Should Be Empty  ${stdout}  Failed to Connect CEC to HMC ==> ${stdout}
    Should Be Empty  ${stderr}  Failed to Connect CEC to HMC ==> ${stderr}

    Set Static VMI IP  ${VMI_IP}  ${SUBNET_MASK}  ${GATEWAY}


Suite Teardown Execution
    [Documentation]  Do the post suite teardown.

    Redfish.Logout

Test Teardown Execution
    [Documentation]  Do the post test teardown.

    Redfish.Logout
    FFDC On Test Case Fail
    # Current doesnt collect system dump , so we need to figure out how to - George / Sandhya


Test Setup Execution
    [Documentation]  Do the test setup. Remove error and guard records.

    BMC Execute Command  systemctl unmask obmc-host-crash@0.target
    BMC Execute Command   guard -r
    ${errors} =  Peltool  -l
    ${errors} =  Peltool  -D

    ${sys_dump}=  Check For System Dump
    Redfish Delete All System Dumps


Check For System Dump
    [Documentation]  Check for system dump through Redfish

    ${dump} =  Redfish.Get  /redfish/v1/Systems/system/LogServices/Dump/Entries
    [Return]  ${dump.dict["Members@odata.count"]}

Execute Phyp Command
    [Documentation]  Login to Phyp and execute command
    [Arguments]    ${cmd}
    [Timeout]   1 minute

    # Description of argument(s):
    # cmd         argument for phyp command execution

    SSHLibrary.Open Connection  ${OPENBMC_HOST}  port=2201  newline=CRLF
    Set Default Configuration   newline=CRLF
    ${status}=   Run Keyword And Return Status  SSHLibrary.Login  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}
    Should Be Equal  ${status}  ${True}
    SSHLibrary.Write  ${cmd}
    ${output}=  SSHLibrary.Read  delay=1s
    SSHLibrary.Close Connection
    [Return]  ${output}


Set Static VMI IP
    [Documentation]  Set static VMI IP.
    [Arguments]  ${vmi_ip}  ${subnet}  ${gateway}

    # Description of argument(s):
    # vmi_ip          VMI IP Address.
    # subnet          Subnet IP.
    # gateway         Gateway IP.

    ${active_channel_config} =  Get Active Channel Config
    Set Suite Variable  ${channel_name}  ${active_channel_config['${CHANNEL_NUMBER}']['name']}

    ${data} =  Set Variable
    ...  {"IPv4StaticAddresses": [{"Address": "${vmi_ip}","SubnetMask": "${subnet}","Gateway": "${gateway}"}]}

    ${resp} =  Redfish.Patch  /redfish/v1/Systems/hypervisor/EthernetInterfaces/${channel_name}
    ...  body=${data}  valid_status_codes=[${HTTP_OK}, ${HTTP_ACCEPTED}]


