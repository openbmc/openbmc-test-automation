*** Settings ***
Documentation   This program performs factory data reset, namely,
...             network, host and BMC factory reset.

# Test Parameters:
# GW_IP                The IPaddress of the gateway.
# NET_MASK             The network mask.
# OPENBMC_SERIAL_HOST  The IP for serial port connection.
# OPENBMC_SERIAL_PORT  The port of serial connection.

Resource  ../lib/rest_client.robot
Resource  ../lib/utils.robot
Resource  ../lib/connection_client.robot
Resource  ../lib/oem/ibm/serial_console_client.robot
Resource  ../lib/boot_utils.robot

Suite Setup Execution  Suite Setup Execution
Suite Teardown         Close All Connections

*** Test Cases ***

Verify Network Factory Reset
    [Documentation]  Network factory reset the system and verify that it pings.
    [Tags]  Verify_Network_Factory_Reset

    # Network factory reset erases user config settings which incldes IP,
    # netmask, gateway and route. Before running this test we are checking
    # all these settings and checking whether ping works with BMC host.
    # If factory reset is successful, ping to BMC host should fail as
    # IP address is erased and comes up with zero_conf.

    Network Factory Reset
    ${status}=  Run Keyword And Return Status  Ping Host  ${OPENBMC_HOST}
    Should Be Equal As Strings  ${status}  False
    ...  msg=Network factory reset failed.

Revert to Initial Setup And Verify
    [Documentation]  Revert to initial setup.
    [Tags]  Revert_to_Initial_Setup_And_Verify

    # This test case restores old settings viz. IP address, netmask, gateway
    # and route. Restoring is done through serial port console.
    # If reverting to initial setup is successful, ping to BMC
    # host should pass.

    Configure Initial Settings
    Ping Host  ${OPENBMC_HOST}

Verify Host Factory Reset
    [Documentation]  Host factory reset the system and verify that it clears
    ...  persistence files and any data stored in the read-write and preserved
    ...  volumes created by the host BIOS.

    [Tags]  Verify_Host_Factory_Reset

    Host Factory Reset

    # Check if host factory reset has erased read-write and preserved volumes
    # created by host BIOS.

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

    # Check volumes are not deleted.

    ${cmd_output}  ${stderr}  ${rc}=  BMC Execute Command  df
    Should Contain  ${cmd_output}  pnor-rw  msg=Host factory reset failed.
    Should Contain  ${cmd_output}  pnor-prsv  msg=Host factory reset failed.

    # Check PNOR read-write and preserved files are deleted.

    ${cmd_output}  ${stderr}  ${rc}=  BMC Execute Command  ls /media/pnor-prsv
    Should Be Empty  ${cmd_output}  msg=Host factory reset failed.

Verify BMC Factory Reset
    [Documentation]  BMC factory reset the system and verify that it clears
    ...  volumes and persistence files created by the BMC processes.
    ...  This reset occurs only on the next BMC reboot.

    [Tags]  Verify_BMC_Factory_Reset

    BMC Factory Reset

    # Check if BMC factory reset has erased read-write and preserved volumes
    # created by BMC.

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

    # Check volumes are not deleted.

    ${cmd_output}  ${stderr}  ${rc}=  BMC Execute Command  df
    Should Contain  ${cmd_output}  var  msg=BMC factory reset failed.

    # Check BMC read-write and preserved files are deleted.

    ${cmd_output}  ${stderr}  ${rc}=  BMC Execute Command  ls /var
    Should Be Empty  ${cmd_output}  msg=BMC factory reset failed.

*** Keywords ***

Suite Setup Execution
    [Documentation]  Do test suite setup tasks.

    Open Connection And Log In

    # Check whether gateway IP is reachable.
    Ping Host  ${GW_IP}
    Should Not Be Empty  ${NET_MASK}  msg=Netmask not provided.

    # Check whether serial console IP is reachable and responding
    # to telnet command.
    Open Telnet Connection To BMC Serial Console

Network Factory Reset
    [Documentation]  Network factory reset the BMC node.

    ${data}=  Create Dictionary  data=@{EMPTY}
    Run Keyword And Ignore Error  OpenBMC Post Request
    ...  ${XYZ_NETWORK_MANAGER}/action/Reset  data=${data}

    # Reboot BMC to apply network factory reset.
    Execute Command On BMC  /sbin/reboot

    Sleep  3 min

Host Factory Reset
    [Documentation]  Host factory reset the BMC node.

    ${data}=  Create Dictionary  data=@{EMPTY}
    Run Keyword And Ignore Error  OpenBMC Post Request
    ...  ${SOFTWARE_VERSION_URI}/action/Reset  data=${data}

BMC Factory Reset
    [Documentation]  BMC factory reset the BMC node.

    ${data}=  Create Dictionary  data=@{EMPTY}
    Run Keyword And Ignore Error  OpenBMC Post Request
    ...  ${SOFTWARE_VERSION_URI}/action/Reset  data=${data}

    # Reboot BMC to apply BMC factory reset.

    OBMC Reboot (off)
