*** Settings ***
Documentation  This module contains keywords within tests/obmc_boot_test that
...  are points at which to call plug-ins.

Resource  obmc_driver_vars.txt

*** Keywords ***
Call Point Setup
    [Documentation]  Call any plugins that have a cp_setup program
    [Teardown]  Log to Console  **Plugin** end call point: cp_setup${\n}

    Log to Console  ${\n}**Plugin** start call point: cp_setup

Call Point Pre Boot
    [Documentation]  Call any plugins that have a cp_pre_boot program
    [Teardown]  Log to Console  **Plugin** end call point: cp_pre_boot${\n}

    Log to Console  ${\n}**Plugin** start call point: cp_pre_boot

Call Point Post Boot
    [Documentation]  Call any plugins that have a cp_post_boot program
    [Teardown]  Log to Console  **Plugin** end call point: cp_post_boot${\n}

    Log to Console  ${\n}**Plugin** start call point: cp_post_boot

Call Point FFDC
    [Documentation]  Call any plugins that have a cp_ffdc program
    [Teardown]  Log to Console  **Plugin** end call point: cp_ffdc${\n}

    Log to Console  ${\n}**Plugin** start call point: cp_ffdc

Call Point Stop Check
    [Documentation]  Call any plugins that have a cp_stop_check program
    [Teardown]  Log to Console  **Plugin** end call point: cp_stop_check${\n}

    Log to Console  ${\n}**Plugin** start call point: cp_stop_check
