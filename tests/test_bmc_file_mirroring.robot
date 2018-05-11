*** Settings ***
Documentation  Test BMC file mirroring sync from primary flash chip to
...  alternate flash chip side.

Resource       ../lib/openbmc_ffdc.robot
Library        ../lib/bmc_ssh_utils.py

Test Teardown  Test Teardown Execution

*** Test Cases ***

Test BMC Alt Side Mirroring
    [Documentation]  Verify the modified file is synced to alt flash side.
    [Tags]  Test_BMC_Alt_Side_Mirroring

    # BMC file sync list.
    # Example output from "cat /etc/synclist" file:
    # /etc/dropbear/
    # /etc/group
    # /etc/gshadow
    # /etc/hostname
    # /etc/machine-id
    # /etc/passwd
    # /etc/shadow
    # /etc/ssl/
    # /etc/ssl/certs/nginx/
    # /etc/ssl/private/
    # /etc/systemd/network/

    # Save off the original hostname.
    ${orig_hostname}  ${stderr}  ${rc}=  BMC Execute Command
    ...  cat /etc/hostname
    Set Suite Variable  ${hostname}  ${orig_hostname}

    BMC Execute Command  echo "mirror-file" > /etc/hostname

    # File "hostname" should have synced to alt media space.
    # Example output from "ls /media/alt/var/persist/etc/":
    # group  group-  gshadow  gshadow-  hostname  machine-id  ssl  systemd

    ${curr_hostname}  ${stderr}  ${rc}=  BMC Execute Command
    ...  cat /media/alt/var/persist/etc/hostname

    Should Be Equal As Strings  ${curr_hostname}  mirror-file
    ...  msg=hostname primary file is not synced to the alt flash chip side.

*** Keywords ***

Test Teardown Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail
    BMC Execute Command  echo ${hostname} > /etc/hostname

