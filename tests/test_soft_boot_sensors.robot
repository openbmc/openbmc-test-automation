*** Settings ***
Documentation   Suite for testing non sensors.

Library      ../lib/state_map.py
Resource     ../lib/utils.robot
Resource     ../lib/boot_utils.robot
Resource     ../lib/state_manager.robot
Resource     ../lib/openbmc_ffdc.robot

Test Teardown     Post Test Case Execution

*** Variables ***

${stack_mode}   skip

*** Test Cases ***

Verify Boot AttemptsLeft At Standby
    [Documentation]  Verify system boot attempts on various boot states.
    [Tags]  Verify_Boot_AttemptsLeft_At_Standby
    [Template]  Validate Boot AttemptsLeft

    # Example: Expected state
    # "data": {
    #    "/xyz/openbmc_project/state/host0": {
    #      "AttemptsLeft": 3,
    #      "BootProgress": "xyz.openbmc_project.State.Boot.Progress.ProgressStages.Unspecified",
    #      "CurrentHostState": "xyz.openbmc_project.State.Host.HostState.Off",
    #      "OperatingSystemState": "xyz.openbmc_project.State.OperatingSystem.Status.OSStatus.Inactive",
    #      "RequestedHostTransition": "xyz.openbmc_project.State.Host.Transition.Off"
    #    }
    # }

    # System at standby    AttemptsLeft
    Reboot                 3


Verify Boot AttemptsLeft At Host Booted
    [Tags]  Verify_Boot_AttemptsLeft_At_Host_Booted
    [Template]  Validate Boot AttemptsLeft

    # System at standby    AttemptsLeft
    Booted                 3


Verify Boot AttemptsLeft When Host Reboot
    [Tags]  Verify_Boot_AttemptsLeft_When_Host_Reboot
    [Template]  Validate Boot AttemptsLeft

    # System at standby    AttemptsLeft
    RebootHost             2


Verify Boot AttemptsLeft When Power Off
    [Tags]  Verify_Boot_AttemptsLeft_When_Power_Off
    [Template]  Validate Boot AttemptsLeft

    # System at standby    AttemptsLeft
    Ready                  2


Verify Boot Sensor States At Ready
    [Documentation]  Verify system boot states at "Ready" state.
    [Tags]  Verify_Boot_Sensor_States_At_Ready
    [Template]  Valid Boot States

    # Example: Expected state
    # "data": {
    #    "/xyz/openbmc_project/state/bmc0": {
    #      "CurrentBMCState": "xyz.openbmc_project.State.BMC.BMCState.Ready",
    #      "RequestedBMCTransition": "xyz.openbmc_project.State.BMC.Transition.None"
    #    },
    #    "/xyz/openbmc_project/state/chassis0": {
    #      "CurrentPowerState": "xyz.openbmc_project.State.Chassis.PowerState.Off",
    #      "RequestedPowerTransition": "xyz.openbmc_project.State.Chassis.Transition.Off"
    #    },
    #    "/xyz/openbmc_project/state/host0": {
    #      "AttemptsLeft": 3,
    #      "BootProgress": "xyz.openbmc_project.State.Boot.Progress.ProgressStages.Unspecified",
    #      "CurrentHostState": "xyz.openbmc_project.State.Host.HostState.Off",
    #      "OperatingSystemState": "xyz.openbmc_project.State.OperatingSystem.Status.OSStatus.Inactive",
    #      "RequestedHostTransition": "xyz.openbmc_project.State.Host.Transition.Off"
    #    }
    # }

    # System at standby.
    Off


Verify Boot Sensor States On Reboot Ready
    [Documentation]  Verify system boot states at "Ready" state.
    [Tags]  Verify_Boot_Sensor_States_On_Reboot_Ready
    [Template]  Valid Boot States

    # Example: Expected state
    # "data": {
    #    "/xyz/openbmc_project/state/bmc0": {
    #      "CurrentBMCState": "xyz.openbmc_project.State.BMC.BMCState.Ready",
    #      "RequestedBMCTransition": "xyz.openbmc_project.State.BMC.Transition.None"
    #    },
    #    "/xyz/openbmc_project/state/chassis0": {
    #      "CurrentPowerState": "xyz.openbmc_project.State.Chassis.PowerState.Off",
    #      "RequestedPowerTransition": "xyz.openbmc_project.State.Chassis.Transition.Off"
    #    },
    #    "/xyz/openbmc_project/state/host0": {
    #      "AttemptsLeft": 3,
    #      "BootProgress": "xyz.openbmc_project.State.Boot.Progress.ProgressStages.Unspecified",
    #      "CurrentHostState": "xyz.openbmc_project.State.Host.HostState.Off",
    #      "OperatingSystemState": "xyz.openbmc_project.State.OperatingSystem.Status.OSStatus.Inactive",
    #      "RequestedHostTransition": "xyz.openbmc_project.State.Host.Transition.Off"
    #    }
    # }

    # BMC on reset to standby.
    Reboot


Verify Boot Sensor States At Running
    [Documentation]  Verify system boot states at "Running" state.
    [Tags]  Verify_Boot_Sensor_States_At_Running
    [Template]  Valid Boot States

    # Example: Expected state
    # "data": {
    #    "/xyz/openbmc_project/state/bmc0": {
    #      "CurrentBMCState": "xyz.openbmc_project.State.BMC.BMCState.Ready",
    #      "RequestedBMCTransition": "xyz.openbmc_project.State.BMC.Transition.None"
    #   },
    #   "/xyz/openbmc_project/state/chassis0": {
    #      "CurrentPowerState": "xyz.openbmc_project.State.Chassis.PowerState.On",
    #      "RequestedPowerTransition": "xyz.openbmc_project.State.Chassis.Transition.Off"
    #   },
    #   "/xyz/openbmc_project/state/host0": {
    #      "AttemptsLeft": 2,
    #      "BootProgress": "xyz.openbmc_project.State.Boot.Progress.ProgressStages.MotherboardInit",
    #      "CurrentHostState": "xyz.openbmc_project.State.Host.HostState.Running",
    #      "OperatingSystemState": "xyz.openbmc_project.State.OperatingSystem.Status.OSStatus.Inactive",
    #      "RequestedHostTransition": "xyz.openbmc_project.State.Host.Transition.On"
    #   }
    # }

    # System at Running state but during initial state.
    Running


Verify Boot Sensor States At Host Booted
    [Documentation]  Verify system boot states when host is booted.
    [Tags]  Verify_Boot_Sensor_States_At_Host_Booted
    [Template]  Valid Boot States

    # Example: Expected state
    # "data": {
    #    "/xyz/openbmc_project/state/bmc0": {
    #      "CurrentBMCState": "xyz.openbmc_project.State.BMC.BMCState.Ready",
    #      "RequestedBMCTransition": "xyz.openbmc_project.State.BMC.Transition.None"
    #   },
    #   "/xyz/openbmc_project/state/chassis0": {
    #      "CurrentPowerState": "xyz.openbmc_project.State.Chassis.PowerState.On",
    #      "RequestedPowerTransition": "xyz.openbmc_project.State.Chassis.Transition.Off"
    #   },
    #   "/xyz/openbmc_project/state/host0": {
    #      "AttemptsLeft": 3,
    #      "BootProgress": "xyz.openbmc_project.State.Boot.Progress.ProgressStages.OSStart",
    #      "CurrentHostState": "xyz.openbmc_project.State.Host.HostState.Running",
    #      "OperatingSystemState": "xyz.openbmc_project.State.OperatingSystem.Status.OSStatus.BootComplete",
    #      "RequestedHostTransition": "xyz.openbmc_project.State.Host.Transition.On"
    #   }
    # }

    # System when host is booted.
    Booted


Verify Boot Sensor States RR on Host Booted
    [Documentation]  Verify system boot states post BMC reset.
    [Tags]  Verify_Boot_Sensor_States_RR_on_Host_Booted
    [Template]  Valid Boot States

    # Example: Expected state
    # "data": {
    #    "/xyz/openbmc_project/state/bmc0": {
    #      "CurrentBMCState": "xyz.openbmc_project.State.BMC.BMCState.Ready",
    #      "RequestedBMCTransition": "xyz.openbmc_project.State.BMC.Transition.None"
    #   },
    #   "/xyz/openbmc_project/state/chassis0": {
    #      "CurrentPowerState": "xyz.openbmc_project.State.Chassis.PowerState.On",
    #      "RequestedPowerTransition": "xyz.openbmc_project.State.Chassis.Transition.Off"
    #   },
    #   "/xyz/openbmc_project/state/host0": {
    #      "AttemptsLeft": 3,
    #      "BootProgress": "xyz.openbmc_project.State.Boot.Progress.ProgressStages.OSStart",
    #      "CurrentHostState": "xyz.openbmc_project.State.Host.HostState.Running",
    #      "OperatingSystemState": "xyz.openbmc_project.State.OperatingSystem.Status.OSStatus.BootComplete",
    #      "RequestedHostTransition": "xyz.openbmc_project.State.Host.Transition.On"
    #   }
    # }

    # System when host is booted.
    ResetReload


*** Keywords ***

Validate Boot AttemptsLeft
    [Documentation]  Verify boot attempts for a given system state.
    [Arguments]  ${sys_state}  ${expected_attempts_left}

    # Description of argument(s):
    # sys_state    A user-defined boot state (e.g. "Off", "On", etc).
    #              See VALID_BOOT_STATES in state_map.py.
    # expected_attempts_left     Boot attempts left.

    Choose Boot And Run  ${sys_state}
    ${atempts_left}=  Read Attribute  ${HOST_STATE_URI}  AttemptsLeft
    Should Be True  ${atempts_left} == ${expected_attempts_left}


Valid Boot States
    [Documentation]  Verify boot states for a given system state.
    [Arguments]  ${sys_state}

    # Description of argument(s):
    # sys_state    A user-defined boot state (e.g. "Off", "On", etc).
    #              See VALID_BOOT_STATES in state_map.py.

    Choose Boot And Run  ${sys_state}
    ${boot_states}=  Get Boot State
    ${valid_state}=  Valid Boot State  ${sys_state}  ${boot_states}
    Should Be True  ${valid_state}


Choose Boot And Run
    [Documentation]  Choose system boot type.
    [Arguments]  ${option}

    # Description of argument(s):
    # option    Boot type (e.g. "Off", "On", "Reboot", etc.).

    Run Keyword If  '${option}' == 'Off'
    ...    Initiate Host PowerOff
    ...  ELSE IF  '${option}' == 'Reboot'
    ...    Run Keywords  Initiate Host PowerOff  AND  Initiate BMC Reboot
    ...                  AND  Wait For BMC Ready
    ...  ELSE IF  '${option}' == 'Running'
    ...    Power On Till Chassis Is On
    ...  ELSE IF  '${option}' == 'Booted'
    ...    Initiate Host Boot
    ...  ELSE IF  '${option}' == 'RebootHost'
    ...    Initiate Host Reboot
    ...  ELSE IF  '${option}' == 'ResetReload'
    ...    Reboot Host And Expect Runtime


Power On Till Chassis Is On
    [Documentation]  Initiate power on and check till chassis state is just
    ...              turned "On".

    # TODO: Move to smart power off once ready.
    Initiate Host PowerOff
    Initiate Host Boot  wait=${0}
    Wait Until Keyword Succeeds  2 min  10 sec  Is Chassis On

    # TODO: Find better mechanism instead of wait.
    Sleep  20 Sec


Reboot Host And Expect Runtime
    [Documentation]  Initiate reset reload when host is booted.

    Initiate BMC Reboot
    Wait Until Keyword Succeeds  10 min  10 sec  Is OS Booted
    Verify BMC RTC And UTC Time Drift


Post Test Case Execution
   [Documentation]  Do the post test teardown.
   # - Capture FFDC on test failure.
   # - Delete error logs.
   # - Close all open SSH connections.
   # - Clear all REST sessions.

   FFDC On Test Case Fail
   Delete Error Logs
   Close All Connections

