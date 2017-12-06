*** Settings ***
Documentation  Verify EEH recovery on the integrated storage controller.
Library     SSHLibrary
Library     String
Library     ../lib/bmc_ssh_utils.py
Resource    ../lib/resource.txt
Resource    ../syslib/utils_os.robot

# This test case verifies the correct operation of EEH on the integrated
# storage controller. It should be verified with all supported distros.
# The injection command:
# echo <pe_num>:<mode>:<type>:<address>:<mask> > /sys/kernel/debug/powerpc/PCIxxxx/err_injct
# Input arguments to injection command:
#   pe_num: determined from the output of
#          'cat /sys/bus/pci/devices/xxxx:xx:xx.x/eeh_pe_config_addr'
#          where the xxxx.xx.xx.x is the PCI location of the device you want.
#   mode: 0 for 32-bit BARs and 64-bit non-prefetchable BARs
#         1 for 64-bit prefetchable BARs
#   type: error function to use:
#          0 to inject on an MMIO load
#          4 to inject on a config load--Not recommended for standard
#            injection trials.
#          6 to inject on an MMIO writes
#         10 to inject on a CFG write
#   address, mask: if you do not care to specify which endpoint under the
#      slot is to be frozen, use a value of '0' for both the address and mask.
#   xxxx: the PCI domain location of the device.
# Example:
# echo 5:0:6:3fe280810000:fffffffffffff800 > /sys/kernel/debug/powerpc/PCI0005/err_injct
# Expected output:
# HTX Runs mdt.hdbuster and doesn't log errors after error injections.
# Glossary:
# EEH:
#   Enhanced I/O Error Handling is an error-recovery mechanism for errors that
#   occur during load and store operations on the PCI bus.
# MDT:
#   Master device table is a collection of hardware devices on the system for
#   which HTX exercisers can be run.
# mdt.hdbuster:
#   MDT for disk storage device testing. Uses 0s and FFs for data patterns.
# HTX error log file /tmp/htxerr
#   Records all the errors that occur. If there's no error during the test, it
#   should be empty.
#   TODO: Check if monitoring dmesg entries adds value.

Suite Setup  Suite Initialization
Suite Teardown  Collect HTX Log Files
*** Variables ***
${DURATION}  4 minutes  # -v argument, for how long to repeat the injection.
${TYPE}  4  # -v argument, EEH error function to use, default is 4.
${lspci_cmd}  lspci -D | grep Marvell

*** Test Cases ***
Test EEH Operation
    [Documentation]  Inject EEH Errors and check if errors are logged in htx.
    [Tags]  Test_EEH_Operation
    Run MDT Profile
    Repeat Keyword  ${DURATION}  Run Keywords
    ...  Inject EEH Error  AND  Check HTX Run Status  AND  Sleep  1 min
    Shutdown HTX Exerciser

*** Keywords ***
Inject EEH Error
    [Documentation]  Inject EEH error to a PE (Partitionable Endpoint).
    Log  Building the injection command.
    ${pci}=  Get PCI
    ${sub_cmd}=  Make Injection Command  ${pci}
    ${pci}=  Fetch From Left  ${pci}  :
    ${cmd}=  Convert To String
    ...  echo ${sub_cmd} > /sys/kernel/debug/powerpc/PCI${pci}/err_injct
    Log  Proceeding with injection:\n${cmd}\n
    ${output}  ${stderr}  ${rc}=  OS Execute Command  ${cmd}
    Log  ${output}

Get PCI
    [Documentation]  Get the PCI ID for the Marvell adapter.
    ${output}  ${stderr}  ${rc}=  OS Execute Command
    ...  ${lspci_cmd} | cut -d " " -f1 | head -n 1
    [Return]  ${output}

Get Pe Num
    [Documentation]  Get the PE (partitionable endpoint) configuration
    ...  address for the specified PCI.
    [Arguments]  ${pci}=${EMPTY}
    ${output}  ${stderr}  ${rc}=  OS Execute Command
    ...  cut -d "x" -f2 /sys/bus/pci/devices/${pci}/eeh_pe_config_addr
    [Return]  ${output}

Get Mode
    [Documentation]  Determine the 'mode' field value, by checking the device's
    ...  memory information.
    [Arguments]  ${pci}=${EMPTY}
    ${cmd_buf}=  Catenate  lspci -bvs ${pci} | grep "Memory at " |
    ...  grep "64-bit, prefetchable" | wc -l
    ${output}  ${stderr}  ${rc}=  OS Execute Command  ${cmd_buf}
    ${mode}=  Set Variable If  '${output}' == '0'  0  1
    [Return]  ${mode}

Get Address
    [Documentation]  Determine the PE address field.
    [Arguments]  ${pci}=${EMPTY}
    ${output}  ${stderr}  ${rc}=  OS Execute Command
    ...  lspci -vv -s ${pci} | grep "Memory at " | cut -d " " -f5 | head -n 1
    [Return]  ${output}

Get Mask
    [Documentation]  Determine the adress' mask field.
    [Arguments]  ${pci}=${EMPTY}
    ${output}  ${stderr}  ${rc}=  OS Execute Command
    ...  lspci -vv -s ${pci} | grep "Memory at" | head -n 1
    ${size_left}=  Fetch From Right  ${output}  size=
    ${size_right}=  Fetch From Left  ${size_left}  K
    ${size1}=  Convert To Integer  ${size_right}
    ${size}=  Evaluate  ${size1}*1024
    ${size_hex}=  Convert To Hex  ${size}
    ${mask}=  Evaluate  "{:f>16}".format(${size_hex})
    [Return]  ${mask}

Make Injection Command
    [Documentation]  Concatenate the fields to form a valid injection command.
    [Arguments]  ${pci}=${EMPTY}
    ${pe_num}=  Get Pe Num  ${pci}
    ${mode}=  Get Mode  ${pci}
    ${addr}=  Get Address  ${pci}
    ${mask}=  Get Mask  ${pci}
    ${res}=  Catenate  SEPARATOR=:
    ...  ${pe_num}  ${mode}  ${TYPE}  ${addr}  ${mask}
    [Return]  ${res}

Suite Initialization
    Tool Exist  lspci
    Tool Exist  htxcmdline
    Set Suite Variable  ${HTX_MDT_PROFILE}  mdt.hdbuster  children=true
    Create Default MDT Profile
