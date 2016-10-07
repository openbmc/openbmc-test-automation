*** Settings ***
Resource  ./obmc_driver_vars.txt

*** Keywords ***
CP Setup
    [Documentation]  Call any plugins that have a cp_setup program
    [Teardown]  Log  **Plugin** end call point: cp_setup${\n}  console=True

    Log  ${\n}**Plugin** start call poing: cp_setup  console=True

CP Pre Boot
    [Documentation]  Call any plugins that have a cp_pre_boot program
    [Teardown]  Log  **Plugin** end call point: cp_pre_boot${\n}  console=True

    Log  ${\n}**Plugin** start call point: cp_pre_boot  console=True

CP Post Boot
    [Documentation]  Call any plugins that have a cp_post_boot program
    [Teardown]  Log  **Plugin** end call point: cp_post_boot${\n}  console=True

    Log  ${\n}**Plugin** start call point: cp_post_boot  console=True

CP FFDC
    [Documentation]  Call any plugins that have a cp_ffdc program
    [Teardown]  Log  **Plugin** end call point: cp_ffdc${\n}  console=True

    Log  ${\n}**Plugin** start call point: cp_ffdc  console=True

CP Stop Check
    [Documentation]  Call any plugins that have a cp_stop_check program
    [Teardown]  Log  **Plugin** end call point: cp_stop_check${\n}  console=True

    Log  ${\n}**Plugin** start call point: cp_stop_check  console=True
