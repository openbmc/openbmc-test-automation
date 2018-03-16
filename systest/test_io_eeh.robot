*** Settings ***
Documentation  Verify the EEH recovery on the controllers connected to the
...  PCI. This injects an EEH error to every controller installed on the
...  server.

# Test Parameters:

# TYPE                EEH error function to use.
# OPENBMC_HOST        The BMC host name or IP address.
# OS_HOST             The OS host name or IP Address.
# OS_USERNAME         The OS login userid (usually root).
# OS_PASSWORD         The password for the OS login.
# HTX_DURATION        Duration of HTX run (e.g. "8 hours", "30 minutes").
# HTX_INTERVAL        The time delay between consecutive checks of HTX
#                     status, for example, 30s.
#                     In summary: Run HTX for $HTX_DURATION, checking
#                     every $HTX_INTERVAL.

# The injection command:
# echo <pe_num>:<mode>:<type>:<address>:<mask> > /sys/kernel/debug/powerpc/PCIxxxx/err_injct
# Input arguments to injection command:
#   pe_num:  Determined from the output of
#          'cat /sys/bus/pci/devices/xxxx:xx:xx.x/eeh_pe_config_addr'
#          where the xxxx.xx.xx.x is the PCI location of the device you want.
#   mode:    0 for 32-bit BARs and 64-bit non-prefetchable BARs
#         1 for 64-bit prefetchable BARs
#   type:    Error function to use:
#          0 to inject on an MMIO load
#          4 to inject on a config load--Not recommended for standard
#            injection trials.
#          6 to inject on an MMIO writes
#         10 to inject on a CFG write
#   address: If you do not care to specify which endpoint under the
#      slot is to be frozen, use a value of '0'.
#   mask:    If you do not care to specify which endpoint under the
#      slot is to be frozen, use a value of '0'.
#   xxxx:    The PCI domain location of the device.

# Example:
# echo 5:0:6:3fe280810000:fffffffffffff800 > /sys/kernel/debug/powerpc/PCI0005/err_injct
# Expected output:
# HTX Runs mdt.hdbuster or net.mdt and doesn't log errors after error injections.

# Glossary:
# EEH:
#   Enhanced I/O Error Handling is an error-recovery mechanism for errors that
#   occur during load and store operations on the PCI bus.
# MDT:
#   Master device table is a collection of hardware devices on the system for
#   which HTX exercisers can be run.
# mdt.hdbuster:
#   MDT for disk storage device testing. Uses 0s and FFs for data patterns.
# net.mdt:
#   MDT used to test network adapters.
# HTX error log file /tmp/htxerr
#   Records all the errors that occur. If there's no error during the test, it
#   should be empty.
#   TODO: Check if monitoring dmesg entries adds value.

Library         SSHLibrary
Library         String
Library         ../lib/bmc_ssh_utils.py
Resource        ../lib/resource.txt
Resource        ../syslib/utils_os.robot

Suite Setup     Suite Setup Execution
Suite Teardown  Collect HTX Log Files
Test Teardown   FFDC On Test Case Fail

*** Variables ***
${HTX_DURATION}  8 hours
${HTX_INTERVAL}  15 minutes
${TYPE}  0

*** Test Cases ***
Test IO Adapters EEH
    [Documentation]  Inject EEH errors in every ethernet controller and check
    ...  if errors are logged.
    [Tags]  Test_IO_Adapters_EEH

    # Setting HTX_MDT_PROFILE to be used in 'Run MDT Profile' keyword
    Set Suite Variable  ${HTX_MDT_PROFILE}  net.mdt
    # Setting lspci_cmd to be used by 'Get PCI' keyword.
    Set Test Variable  ${lspci_cmd}  lspci -D | grep "Ethernet controller"
    # Setting pci_list to be used in 'Cycle Through PCIs' keyword
    @{pci_list}=  Get PCI
    Set Test Variable  @{pci_list}
    Preconfigure Net MDT
    Run MDT Profile
    Repeat Keyword  ${HTX_DURATION}  Cycle Through PCIs
    Shutdown HTX Exerciser

Test IO Storage EEH
    [Documentation]  Inject EEH Errors and check if errors are logged in htx.
    [Tags]  Test_IO_Storage_EEH

    # Setting HTX_MDT_PROFILE to be used in 'Run MDT Profile' keyword
    Set Suite Variable  ${HTX_MDT_PROFILE}  mdt.hdbuster  children=true
    # Setting lspci_cmd to be used by 'Get PCI' keyword.
    Set Test Variable  ${lspci_cmd}  lspci -D | grep Marvell
    # Setting pci_list to be used in 'Cycle Through PCIs' keyword
    @{pci_list}=  Get PCI
    Set Test Variable  @{pci_list}
    Run MDT Profile
    Repeat Keyword  ${HTX_DURATION}  Cycle Through PCIs
    Shutdown HTX Exerciser

*** Keywords ***
Cycle Through PCIs
    [Documentation]  Run a cycle to make error injections to every PCI
    ...  in the pci_list. Use the list of PCIs.

    :FOR  ${pci}  IN  @{pci_list}
    \  Inject EEH Error  ${pci}
    \  Check HTX Run Status
    \  Run Key U  sleep \ ${HTX_INTERVAL}

Preconfigure Net MDT
    [Documentation]  Run build_net to preconfigure the interfaces to be
    ...  injected with the EEH error.

    OS Execute Command  build_net help y y
    ${output}  ${stderr}  ${rc}=  OS Execute Command
    ...  pingum | egrep "All networks ping Ok"
    Should Contain  ${output}  All networks ping Ok

Inject EEH Error
    [Documentation]  Build and inject the EEH error command.
    [Arguments]  ${pci}=${EMPTY}
    # Description of argument(s):
    # pci   PCI address as domain number (0 to ffff), bus (0 to ff),
    #       slot (0 to 1f) and function (0 to 7).
    #       (e.g. "0000:00:1f.2").

    ${sub_cmd}=  Make Injection Command  ${pci}
    ${pci}=  Fetch From Left  ${pci}  :
    ${cmd}=  Catenate  echo ${sub_cmd} >
    ...  /sys/kernel/debug/powerpc/PCI${pci}/err_injct
    ${output}  ${stderr}  ${rc}=  OS Execute Command  ${cmd}

Get PCI
    [Documentation]  Obtain the PCI IDs for every ethernet controller.
    ${output}  ${stderr}  ${rc}=  OS Execute Command
    ...  ${lspci_cmd} | cut -d " " -f1
    @{pci_list}=  Split To Lines  ${output}
    [Return]  @{pci_list}

Make Injection Command
    [Documentation]  Create the string that will inject the EEH error.
    [Tags]  Create_Injection_Command
    [Arguments]  ${pci}=${EMPTY}
    # Description of argument(s):
    # pci   PCI address as domain number (0 to ffff), bus (0 to ff),
    #       slot (0 to 1f) and function (0 to 7).
    #       (e.g. "0000:00:1f.2").

    ${pe_num}=  Get PE Num  ${pci}
    ${mode}=  Get Mode  ${pci}
    ${address}=  Get Address  ${pci}
    ${mask}=  Get Mask  ${pci}
    ${result}=  Catenate  SEPARATOR=:
    ...  ${pe_num}  ${mode}  ${TYPE}  ${address}  ${mask}
    [Return]  ${result}

Get PE Num
    [Documentation]  Return the PE configuration address of the PCI sent.
    [Tags]  Get_PE_Number
    [Arguments]  ${pci}=${EMPTY}
    # Description of argument(s):
    # pci   PCI address as domain number (0 to ffff), bus (0 to ff),
    #       slot (0 to 1f) and function (0 to 7).
    #       (e.g. "0000:00:1f.2").

    ${output}  ${stderr}  ${rc}=  OS Execute Command
    ...  cut -d "x" -f2 /sys/bus/pci/devices/${pci}/eeh_pe_config_addr
    [Return]  ${output}

Get Mode
    [Documentation]  Return the "mode" field value.
    [Tags]  Get_Mode
    [Arguments]  ${pci}=${EMPTY}
    # Description of argument(s):
    # pci   PCI address as domain number (0 to ffff), bus (0 to ff),
    #       slot (0 to 1f) and function (0 to 7).
    #       (e.g. "0000:00:1f.2").

    ${cmd_buf}=  Catenate  lspci -bvs ${pci} | grep "Memory at" |
    ...  grep "64-bit" | wc -l
    ${output}  ${stderr}  ${rc}=  OS Execute Command  ${cmd_buf}
    ${mode}=  Set Variable If  '${output}'=='0'  0  1
    [Return]  ${mode}

Get Address
    [Documentation]  Obtain the PCI address.
    [Arguments]  ${pci}=${EMPTY}
    # Description of argument(s):
    # pci   PCI address as domain number (0 to ffff), bus (0 to ff),
    #       slot (0 to 1f) and function (0 to 7).
    #       (e.g. "0000:00:1f.2").

    ${cmd_buf}=  Catenate  lspci -vv -s ${pci} | grep "Memory at"
    ...  | cut -d " " -f5 | head -n 1
    ${output}  ${stderr}  ${rc}=  OS Execute Command  ${cmd_buf}
    [Return]  ${output}

Get Mask
    [Documentation]  Return the selected PCI mask.
    [Arguments]  ${pci}=${EMPTY}
    # Description of argument(s):
    # pci   PCI address as domain number (0 to ffff), bus (0 to ff),
    #       slot (0 to 1f) and function (0 to 7).
    #       (e.g. "0000:00:1f.2").

    ${cmd_buf}=  Catenate  lspci -vv -s ${pci} | grep "Memory at"
    ...    | head -n 1 | cut -d "=" -f2
    ${stdout}  ${stderr}  ${rc}=  OS Execute Command  ${cmd_buf}
    ${sze}=  Get Substring  ${stdout}  -2  -1
    ${size}=  Get Substring  ${stdout}  0  -2
    ${size}=  Convert To Integer  ${size}
    ${size}=  Run Keyword If  '${sze}' == 'M'
    ...  Evaluate  ${size}*1024*1024
    ...  ELSE IF  '${sze}' == 'K'
    ...  Evaluate  ${size}*1024
    Log To Console  ${size}
    ${size}=  Convert To Hex  ${size}
    ${mask}=  Evaluate  "{:f>16}".format(${size})
    [Return]  ${mask}

Suite Setup Execution
    [Documentation]  Do suite setup tasks.

    Boot To OS
    Tool Exist  lspci
    Tool Exist  htxcmdline
    Create Default MDT Profile
