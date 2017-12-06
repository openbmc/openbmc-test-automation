*** Settings ***
Library   SSHLibrary
Library   String

Documentation   Verify EEH recovery on the integrated storage controller
# The purpose of this test case is to verify the correct operation of EEH on the integrated storage controller.
# Should be verified with all supported Distros.
#
# So the command will look like this:
# --------------------------------------------------------------------------------------
# The injection command:
# 
# echo pe_no:mode:type:address:mask > /sys/kernel/debug/powerpc/PCIxxxx/err_injct
#
#  input arguments:
#    "xxxx.xx.xx.x" is the location of the device
#    "address:mask" If you do not care to specify which endpoint under
#        the slot is to be frozen, use a value of '0' for both the address and mask.
#    "type" 0 to inject on an MMIO load
#           4 to inject on a config load--Not recommended for standard injection trials.
#           6 to inject on an MMIO writes
#   HTX Run mdt.hdbuster and doesn't log errors
#   TODO: Check if monitoring dmesg entries adds value
#

Suite Setup     Run Keywords    Open Connection     ${HOST_IP}       AND
                ...             Login               ${USERNAME}  ${PASSWORD}
Suite Teardown  Close All Connections

*** Variables ***
${HOST_IP}          127.0.0.1
${USERNAME}         username
${PASSWORD}         password
${TIME}             4
${MDT}              mdt.hdbuster
${TYPE}             4

*** Test Cases ***
Test EEH Operation
    [Tags]              Test_EEH_Operation
    [Documentation]
    Start HTX
    Repeat Keyword      ${TIME} hours
    ...                 Run Keywords        Inject Error   AND   Check HTX Status   AND   Sleep   15 min
    Close HTX
    Inject Error

*** Keywords ***
Start HTX
    [Documentation]     Creates the hdbuster mdt and starts exercising the disks
    Log To Console      Running HTX
    ${profile}=         Execute Command     htxcmdline -sut ${HOST_IP} -createmdt ${MDT}
    Should Contain      ${profile}          mdts are created successfully.
    ${htx_run}=         Execute Command     htxcmdline -run -mdt ${MDT}
    Should Contain      ${htx_run}          Activated

Check HTX Status
    [Documentation]     Checks the status of htx and verifies that the err log is empty
    ${status}=          Execute Command     htxcmdline -status -mdt ${MDT}
    Should Contain      ${status}           Currently running
    ${error}=           Execute Command     htxcmdline -geterrlog
    Should Contain      ${error}            file </tmp/htxerr> is empty

Close HTX
    Log To Console      Closing HTX
    ${shutdown}=        Execute Command     htxcmdline -shutdown -mdt ${MDT}
    Should Contain      ${shutdown}         shutdown successfully

Inject Error
    [Documentation]
    Log To Console      Building the injection command
    ${cmd}=             Make Injection Command
    ${pci}=             Execute Command     lspci -D | grep Marvell | cut -d" " -f1 | cut -d":" -f1
    ${pci2}=            Get Line            ${pci}     0
    ${res}=             Convert To String       echo ${cmd} > /sys/kernel/debug/powerpc/PCI${pci2}/err_injct
    Log To Console      Proceeding with injection:\n${res}\n
    ${res}=             Execute Command     ${res}
    Log To Console      ${res}\n

Get Pci
    [Documentation]     Get the PCI id for the Marvell adapter
    ${pci}=             Execute Command     lspci -D | grep Marvell | cut -d" " -f1
    ${pci2}=            Get Line            ${pci}     0
    [Return]            ${pci2}

Get Pe_no
    [Documentation]     Gets the PE (partitionable endpoint) configuration address for the specified PCI
    ${pci}=             Get Pci
    ${pe_no}=           Execute Command     cat /sys/bus/pci/devices/${pci}/eeh_pe_config_addr | cut -d"x" -f2
    [Return]            ${pe_no}

Get Mode
    [Documentation]
    ${pci}=             Get Pci
    ${info}=            Execute Command     lspci -bvs ${pci} | grep "Memory at "
    ${num}=             Execute Command     echo "${info}" | grep "64-bit, prefetchable" | wc -l
    ${res}=             Set Variable If     '${num}'=='0'    0    1
    [Return]            ${res}

Make Injection Command
    ${pe_no}=           Get Pe_no
    ${mode}=            Get Mode
    ${addr}=            Get Address
    ${mask}=            Get Mask
    ${res}=             Catenate    SEPARATOR=:     ${pe_no}    ${mode}     ${TYPE}     ${addr}  ${mask}
    [Return]            ${res}

Get Address
    [Documentation]
    ${pci}=             Get Pci
    Log To Console      pci: ${pci}
    ${addr}=            Execute Command     lspci -vv -s ${pci} | grep --max-count 1 "Memory at " | cut -d" " -f5
    [Return]            ${addr}

Get Mask
    [Documentation]
    ${pci}=             Get Pci
    ${info}=            Execute Command     lspci -vv -s ${pci}
    ${mem_info}=        Get Lines Containing String     ${info}     Memory at
    ${mem_first}=       Get Line            ${mem_info}     0
    ${size_left}=       Fetch From Right    ${mem_first}    size=
    ${size_right}=      Fetch From Left     ${size_left}    K
    ${size1}=           Convert To Integer  ${size_right}
    ${size}=            Evaluate            ${size1}*1024
    ${size_hex}=        Convert To Hex      ${size}
    ${mask}=            Evaluate            "{:f>16}".format(${size_hex})
    [Return]            ${mask}