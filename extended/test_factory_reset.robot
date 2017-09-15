*** Settings ***
Documentation   This program performs factory data reset, namely,
...             network, host and BMC factory reset on DHCP setup.

Resource  ../lib/rest_client.robot
Resource  ../lib/utils.robot
Resource  ../lib/connection_client.robot
Resource  ../lib/boot_utils.robot
Resource  ../lib/code_update_utils.robot
Resource  ../lib/ipmi_client.robot

*** Test Cases ***

Initiate Factory Reset And Verify
    [Documentation]  Factory reset the system.
    [Tags]  Initiate_Factory_Reset_And_Verify

    Network Factory Reset
    Software Manager Factory Reset

    # Enable field mode.
    Enable Field Mode And Verify Unmount

    # Reboot BMC to apply BMC factory reset.
    OBMC Reboot (off)

    # Check BMC comes up with same IP address.
    Ping Host  ${OPENBMC_HOST}

    # Check if factory reset has erased read-write and preserved volumes
    # created by host BIOS and BMC.

    # Sample output:
    # Filesystem           1K-blocks      Used Available Use% Mounted on
    # dev                     215188         0    215188   0% /dev
    # tmpfs                   216104     14372    201732   7% /run
    # /dev/mtdblock4           14720     14720         0 100% /run/initramfs/ro
    # /dev/mtdblock5            4096       300      3796   7% /run/initramfs/rw
    # cow                       4096       300      3796   7% /
    # tmpfs                   216104         0    216104   0% /dev/shm
    # tmpfs                   216104         0    216104   0% /sys/fs/cgroup
    # tmpfs                   216104         0    216104   0% /tmp
    # tmpfs                   216104        80    216024   0% /var/volatile
    # tmpfs                   216104         0    216104   0% /usr/local
    # ubi7:pnor-rw-9ac69aca    13816        16     13052   0% /media/pnor-rw-9ac69aca
    # /dev/ubiblock7_1         19584     19584         0 100% /media/pnor-ro-9ac69aca
    # ubi7:pnor-prsv             972        32       872   4% /media/pnor-prsv
    # ubi7:pnor-patch          13816        16     13056   0% /usr/local/share/pnor

    # Check PNOR and BMC preserved volumes are not deleted.

    ${cmd_output}  ${stderr}  ${rc}=  BMC Execute Command  df
    Should Contain  ${cmd_output}  pnor-rw  msg=Host factory reset failed.
    Should Contain  ${cmd_output}  pnor-prsv  msg=Host factory reset failed.
    Should Contain  ${cmd_output}  var  msg=BMC factory reset failed.

    # Check PNOR read-write and preserved files are deleted.
    ${cmd_output}  ${stderr}  ${rc}=  BMC Execute Command  ls /media/pnor-prsv
    Should Be Empty  ${cmd_output}  msg=Host factory reset failed.

    # Check flag "Boot Device Selector" comes up with default value
    # "No override" after BMC factory reset.
    ${resp}=  Run IPMI Standard Command  chassis bootparam get 5
    ${boot_dev}=  Get Lines Containing String  ${resp}  Boot Device Selector
    Should Contain  ${boot_dev}  No override  msg=BMC factory reset failed.

*** Keywords ***

Network Factory Reset
    [Documentation]  Network factory reset the BMC node.

    ${data}=  Create Dictionary  data=@{EMPTY}
    Run Keyword And Ignore Error  OpenBMC Post Request
    ...  ${XYZ_NETWORK_MANAGER}/action/Reset  data=${data}

Software Manager Factory Reset
    [Documentation]  Software Manager Factory Reset.

    ${data}=  Create Dictionary  data=@{EMPTY}
    Run Keyword And Ignore Error  OpenBMC Post Request
    ...  ${SOFTWARE_VERSION_URI}/action/Reset  data=${data}

