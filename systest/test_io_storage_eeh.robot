*** Settings ***
Documentation  Verify EEH recovery on the integrated storage controller.
Library  SSHLibrary
Library  String
Library  ../lib/bmc_ssh_utils.py
Resource  ../lib/resource.txt
Resource  ../syslib/utils_os.robot

# This test case verifies the correct operation of EEH on the integrated
# storage controller. It should be verified with all supported Distros.
#
# The injection command:
# echo pe_no:mode:type:address:mask >
#      /sys/kernel/debug/powerpc/PCIxxxx/err_injct
#
#  input arguments:
#    "xxxx.xx.xx.x" is the location of the device
#    "address:mask" If you do not care to specify which endpoint under
#        the slot is to be frozen, use a value of '0' for both the
#        address and mask.
#    "type" Error function to use
#           0 to inject on an MMIO load
#           4 to inject on a config load--Not recommended for standard
#             injection trials.
#           6 to inject on an MMIO writes
#          10 to inject on a CFG write
#   HTX Run mdt.hdbuster and doesn't log errors
#
# EEH:
#   Enhanced I/O Error Handling, is an error-recovery mechanism for errors that
#   occur during load and store operations on the PCI bus.
# MDT:
#   Master device table. Its a collection of hardware devices on the system for
#   which HTX exercisers can run test.
# mdt.hdbuster:
#   MDT for disk storage devices testing. Uses 0's and FF's for data pattern.
# HTX error log file /tmp/htxerr
#   Records all the errors that occur. If there's no error during the test, it
#   should be empty.
#   TODO: Check if monitoring dmesg entries adds value

Suite Setup  Suite Initialization
Suite Teardown  Collect HTX Log Files
*** Variables ***
${INTERVAL}  4  # How many times to repeat the injection
${TYPE}  4  # EEH error function to use, default is 4, inject on a config load
${lspci_cmd}  lspci -D | grep Marvell

*** Test Cases ***
Test EEH Operation
    [Documentation]  Inject EEH Errors and check if errors are logged in htx.
    [Tags]  Test_EEH_Operation
    Run MDT Profile
    Repeat Keyword  ${INTERVAL} hours  Run Keywords
    ...  Inject EEH Error  AND  Check HTX Run Status  AND  Sleep  15 min
    Shutdown HTX Exerciser

*** Keywords ***
Inject EEH Error
    [Documentation]  Inject EEH error to a PE (Partitionable Endpoint).
    Log  Building the injection command
    ${cmd}=  Make Injection Command
    ${output}=  Execute Command On OS
    ...  ${lspci_cmd} | cut -d" " -f1 | cut -d":" -f1
    ${pci}=  Get Line  ${output}  0
    ${res}=  Convert To String
    ...  echo ${cmd} > /sys/kernel/debug/powerpc/PCI${pci}/err_injct
    Log  Proceeding with injection:\n${res}\n
    ${output}=  Execute Command On OS  ${res}
    Log  ${output}

Get Pci
    [Documentation]  Get the PCI id for the Marvell adapter.
    ${output}=  Execute Command On OS
    ...  ${lspci_cmd} | cut -d" " -f1
    ${pci}=  Get Line  ${output}  0
    [Return]  ${pci}

Get Pe_no
    [Documentation]  Get the PE (partitionable endpoint) configuration
    ...  address for the specified PCI.
    ${pci}=  Get Pci
    ${output}=  Execute Command On OS
    ...  cat /sys/bus/pci/devices/${pci}/eeh_pe_config_addr | cut -d"x" -f2
    [Return]  ${output}

Get Mode
    ${pci}=  Get Pci
    ${output}=  Execute Command On OS
    ...  lspci -bvs ${pci} | grep "Memory at "
    ${output}=  Execute Command On OS
    ...  echo "${output}" | grep "64-bit, prefetchable" | wc -l
    ${res}=  Set Variable If  '${output}'=='0'  0  1
    [Return]  ${res}

Make Injection Command
    ${pe_no}=  Get Pe_no
    ${mode}=  Get Mode
    ${addr}=  Get Address
    ${mask}=  Get Mask
    ${res}=  Catenate  SEPARATOR=:
    ...  ${pe_no}  ${mode}  ${TYPE}  ${addr}  ${mask}
    [Return]  ${res}

Get Address
    ${pci}=  Get Pci
    ${output}=  Execute Command On OS
    ...  lspci -vv -s ${pci} | grep --max-count 1 "Memory at " | cut -d" " -f5
    [Return]  ${output}

Get Mask
    ${pci}=  Get Pci
    ${output}=  Execute Command On OS  lspci -vv -s ${pci}
    ${mem_info}=  Get Lines Containing String  ${output}  Memory at
    ${mem_first}=  Get Line  ${mem_info}  0
    ${size_left}=  Fetch From Right  ${mem_first}  size=
    ${size_right}=  Fetch From Left  ${size_left}  K
    ${size1}=  Convert To Integer  ${size_right}
    ${size}=  Evaluate  ${size1}*1024
    ${size_hex}=  Convert To Hex  ${size}
    ${mask}=  Evaluate  "{:f>16}".format(${size_hex})
    [Return]  ${mask}

Suite Initialization
    Tool Exist  lspci
    Tool Exist  htxcmdline
    Set Suite Variable  ${HTX_MDT_PROFILE}  mdt.hdbuster  children=true
    Create Default MDT Profile