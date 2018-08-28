#!/usr/bin/env python

r"""
State Manager module:

   - Defines Valid states of the system

"""
import os
import re
import sys

from robot.libraries.BuiltIn import BuiltIn

robot_pgm_dir_path = os.path.dirname(__file__) + os.sep
repo_data_dir_path = re.sub('/lib', '/data', robot_pgm_dir_path)
sys.path.append(repo_data_dir_path)

import gen_robot_keyword as keyword
import variables as var

BuiltIn().import_resource("state_manager.robot")
BuiltIn().import_resource("rest_client.robot")

# We will build eventually the mapping for warm, cold reset as well.
VALID_STATES = {
    'reboot':
    {
        # (Power Policy, BMC state, Chassis State, Host State)
        ('LEAVE_OFF', 'Ready', 'Off', 'Off'),
        ('ALWAYS_POWER_ON', 'Ready', 'On', 'Running'),
        ('ALWAYS_POWER_ON', 'Ready', 'On', 'Off'),
        ('RESTORE_LAST_STATE', 'Ready', 'On', 'Running'),
        ('RESTORE_LAST_STATE', 'Ready', 'On', 'Off'),
        ('ALWAYS_POWER_OFF', 'Ready', 'On', 'Running'),
        ('ALWAYS_POWER_OFF', 'Ready', 'Off', 'Off'),
    },
}

VALID_BOOT_STATES = {
    'Off':  # Valid states when Host is Off.
    {
        # (BMC , Chassis , Host , BootProgress, OperatingSystemState)
        (
            "xyz.openbmc_project.State.BMC.BMCState.Ready",
            "xyz.openbmc_project.State.Chassis.PowerState.Off",
            "xyz.openbmc_project.State.Host.HostState.Off",
            "xyz.openbmc_project.State.Boot.Progress.ProgressStages.Unspecified",
            "xyz.openbmc_project.State.OperatingSystem.Status.OSStatus.Inactive"
        ),
    },
    'Reboot':  # Valid states when BMC reset to standby.
    {
        # (BMC , Chassis , Host , BootProgress, OperatingSystemState)
        (
            "xyz.openbmc_project.State.BMC.BMCState.Ready",
            "xyz.openbmc_project.State.Chassis.PowerState.Off",
            "xyz.openbmc_project.State.Host.HostState.Off",
            "xyz.openbmc_project.State.Boot.Progress.ProgressStages.Unspecified",
            "xyz.openbmc_project.State.OperatingSystem.Status.OSStatus.Inactive"
        ),
    },
    'Running':  # Valid states when Host is powering on.
    {
        # (BMC , Chassis , Host , BootProgress, OperatingSystemState)
        (
            "xyz.openbmc_project.State.BMC.BMCState.Ready",
            "xyz.openbmc_project.State.Chassis.PowerState.On",
            "xyz.openbmc_project.State.Host.HostState.Running",
            "xyz.openbmc_project.State.Boot.Progress.ProgressStages.MotherboardInit",
            "xyz.openbmc_project.State.OperatingSystem.Status.OSStatus.Inactive"
        ),
    },
    'Booted':  # Valid state when Host is booted.
    {
        # (BMC , Chassis , Host , BootProgress, OperatingSystemState)
        (
            "xyz.openbmc_project.State.BMC.BMCState.Ready",
            "xyz.openbmc_project.State.Chassis.PowerState.On",
            "xyz.openbmc_project.State.Host.HostState.Running",
            "xyz.openbmc_project.State.Boot.Progress.ProgressStages.OSStart",
            "xyz.openbmc_project.State.OperatingSystem.Status.OSStatus.BootComplete"
        ),
    },
    'ResetReload':  # Valid state BMC reset reload when host is booted.
    {
        # (BMC , Chassis , Host , BootProgress, OperatingSystemState)
        (
            "xyz.openbmc_project.State.BMC.BMCState.Ready",
            "xyz.openbmc_project.State.Chassis.PowerState.On",
            "xyz.openbmc_project.State.Host.HostState.Running",
            "xyz.openbmc_project.State.Boot.Progress.ProgressStages.OSStart",
            "xyz.openbmc_project.State.OperatingSystem.Status.OSStatus.BootComplete"
        ),
    },
}


class state_map():

    def get_boot_state(self):
        r"""
        Return the system state as a tuple of bmc, chassis, host state,
        BootProgress and OperatingSystemState.
        """

        status, state = keyword.run_key("Read Properties  "
                                        + var.SYSTEM_STATE_URI + "enumerate")
        bmc_state = state[var.SYSTEM_STATE_URI + 'bmc0']['CurrentBMCState']
        chassis_state = \
            state[var.SYSTEM_STATE_URI + 'chassis0']['CurrentPowerState']
        host_state = state[var.SYSTEM_STATE_URI + 'host0']['CurrentHostState']
        boot_state = state[var.SYSTEM_STATE_URI + 'host0' + 'attr']['BootProgress']
        os_state = \
            state[var.SYSTEM_STATE_URI + 'host0']['OperatingSystemState']

        return (str(bmc_state),
                str(chassis_state),
                str(host_state),
                str(boot_state),
                str(os_state))

    def valid_boot_state(self, boot_type, state_set):
        r"""
        Validate a given set of states is valid.

        Description of argument(s):
        boot_type                   Boot type (e.g. off/running/host booted
                                    etc.)
        state_set                   State set (e.g.bmc,chassis,host,
                                    BootProgress,OperatingSystemState)
        """

        if state_set in set(VALID_BOOT_STATES[boot_type]):
            return True
        else:
            return False
