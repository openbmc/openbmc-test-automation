#!/usr/bin/env python3

r"""
Variable constants applicable to all OpenBMC test.
"""

import os

from robot.libraries.BuiltIn import BuiltIn

OPENBMC_BASE_URI = "/xyz/openbmc_project/"
OPENBMC_BASE_DBUS = "xyz.openbmc_project."

# Generic Dbus commands.
OPENBMC_DBUS_GET_PROPERTY = "busctl get-property "
OPENBMC_DBUS_SET_PROPERTY = "busctl set-property "

# org open power base URI.
OPENPOWER_BASE_URI = "/org/open_power/"
OPENPOWER_CONTROL = OPENPOWER_BASE_URI + "control/"
OPENPOWER_SENSORS = OPENPOWER_BASE_URI + "sensors/"

# REST URI base endpoint paths.
CONTROL_URI = OPENBMC_BASE_URI + "control/"
# Continue to keep to support legacy code.
SETTINGS_URI = "/org/openbmc/settings/"
WATCHDOG_URI = OPENBMC_BASE_URI + "watchdog/"
TIME_MANAGER_URI = OPENBMC_BASE_URI + "time/"
NETWORK_MANAGER = OPENBMC_BASE_URI + "network/"
NETWORK_RESOURCE = "xyz.openbmc_project.Network.IP.Protocol.IPv4"
# SNMP
SNMP_MANAGER_URI = NETWORK_MANAGER + "snmp/manager/"
# Sensors base variables.
SENSORS_URI = OPENBMC_BASE_URI + "sensors/"
# Thermal Control base variables
THERMAL_CONTROL_URI = CONTROL_URI + "thermal/0"
THERMAL_METRICS = "ThermalSubsystem/ThermalMetrics"

COMPONENT_NAME_OF_POWER_SUPPLY = "powersupply"

# State Manager base variables
BMC_REBOOT_TRANS = "xyz.openbmc_project.State.BMC.Transition.Reboot"

HOST_POWEROFF_TRANS = "xyz.openbmc_project.State.Host.Transition.Off"
HOST_POWERON_TRANS = "xyz.openbmc_project.State.Host.Transition.On"
HOST_REBOOT_TRANS = "xyz.openbmc_project.State.Host.Transition.Reboot"
HOST_POWEROFF_STATE = "xyz.openbmc_project.State.Host.HostState.Off"
HOST_POWERON_STATE = "xyz.openbmc_project.State.Host.HostState.Running"

CHASSIS_POWEROFF_TRANS = "xyz.openbmc_project.State.Chassis.Transition.Off"
CHASSIS_POWERON_TRANS = "xyz.openbmc_project.State.Chassis.Transition.On"
CHASSIS_POWEROFF_STATE = "xyz.openbmc_project.State.Chassis.PowerState.Off"
CHASSIS_POWERON_STATE = "xyz.openbmc_project.State.Chassis.PowerState.On"

# State Manager URI variables.
SYSTEM_STATE_URI = OPENBMC_BASE_URI + "state/"
BMC_STATE_URI = OPENBMC_BASE_URI + "state/bmc0/"
HOST_STATE_URI = OPENBMC_BASE_URI + "state/host0/"
CHASSIS_STATE_URI = OPENBMC_BASE_URI + "state/chassis0/"
HOST_WATCHDOG_URI = OPENBMC_BASE_URI + "watchdog/host0/"

# OS state for x86 architecture
OS_STATE_URI = OPENBMC_BASE_URI + "state/os/"

# Logging URI variables
BMC_LOGGING_URI = OPENBMC_BASE_URI + "logging/"
BMC_LOGGING_ENTRY = BMC_LOGGING_URI + "entry/"
REDFISH_SYSTEM_ID = BuiltIn().get_variable_value(
    "${SYSTEM_ID}", default="system"
)
REDFISH_BMC_LOGGING_ENTRY = (
    "/redfish/v1/Systems/"
    + REDFISH_SYSTEM_ID
    + "/LogServices/EventLog/Entries/"
)


# Software manager version
SOFTWARE_VERSION_URI = OPENBMC_BASE_URI + "software/"
ACTIVE = "xyz.openbmc_project.Software.Activation.Activations.Active"
READY = "xyz.openbmc_project.Software.Activation.Activations.Ready"
INVALID = "xyz.openbmc_project.Software.Activation.Activations.Invalid"
ACTIVATING = "xyz.openbmc_project.Software.Activation.Activations.Activating"
NOTREADY = "xyz.openbmc_project.Software.Activation.Activations.NotReady"
FAILED = "xyz.openbmc_project.Software.Activation.Activations.Failed"

SOFTWARE_ACTIVATION = "xyz.openbmc_project.Software.Activation"
REQUESTED_ACTIVATION = SOFTWARE_ACTIVATION + ".RequestedActivations"
REQUESTED_ACTIVE = REQUESTED_ACTIVATION + ".Active"
REQUESTED_NONE = REQUESTED_ACTIVATION + ".None"

SOFTWARE_PURPOSE = "xyz.openbmc_project.Software.Version.VersionPurpose"
VERSION_PURPOSE_HOST = SOFTWARE_PURPOSE + ".Host"
VERSION_PURPOSE_BMC = SOFTWARE_PURPOSE + ".BMC"
VERSION_PURPOSE_SYSTEM = SOFTWARE_PURPOSE + ".System"

# Image Upload Directory Path
IMAGE_UPLOAD_DIR_PATH = "/tmp/images/"

# Inventory URI variables
HOST_INVENTORY_URI = OPENBMC_BASE_URI + "inventory/"
CHASSIS_INVENTORY_URI = HOST_INVENTORY_URI + "system/chassis/"
MOTHERBOARD_INVENTORY_URI = CHASSIS_INVENTORY_URI + "motherboard/"

# Led URI variable
LED_GROUPS_URI = OPENBMC_BASE_URI + "led/groups/"
LED_PHYSICAL_URI = OPENBMC_BASE_URI + "led/physical/"
LED_LAMP_TEST_ASSERTED_URI = LED_GROUPS_URI + "lamp_test/"
LED_PHYSICAL_PS0_URI = LED_PHYSICAL_URI + "cffps1_69/"
LED_PHYSICAL_PS1_URI = LED_PHYSICAL_URI + "cffps1_68/"
LED_PHYSICAL_FAN0_URI = LED_PHYSICAL_URI + "fan0/"
LED_PHYSICAL_FAN2_URI = LED_PHYSICAL_URI + "fan2/"
LED_PHYSICAL_FAN3_URI = LED_PHYSICAL_URI + "fan3/"

# Host control URI variables.
CONTROL_HOST_URI = OPENBMC_BASE_URI + "control/host0/"

# Power restore variables.
POWER_RESTORE_URI = CONTROL_HOST_URI + "power_restore_policy"
CONTROL_DBUS_BASE = "xyz.openbmc_project.Control."

RESTORE_LAST_STATE = CONTROL_DBUS_BASE + "Power.RestorePolicy.Policy.Restore"
ALWAYS_POWER_ON = CONTROL_DBUS_BASE + "Power.RestorePolicy.Policy.AlwaysOn"
ALWAYS_POWER_OFF = CONTROL_DBUS_BASE + "Power.RestorePolicy.Policy.AlwaysOff"

# Dump URI variables.
REST_DUMP_URI = OPENBMC_BASE_URI + "dump/bmc/"
DUMP_ENTRY_URI = REST_DUMP_URI + "entry/"
DUMP_DOWNLOAD_URI = "/download/dump/"
# The path on the BMC where dumps are stored.
DUMP_DIR_PATH = "/var/lib/phosphor-debug-collector/"

# Boot progress variables.
STATE_DBUS_BASE = "xyz.openbmc_project.State."
OS_BOOT_START = STATE_DBUS_BASE + "Boot.Progress.ProgressStages.OSStart"
OS_BOOT_OFF = STATE_DBUS_BASE + "Boot.Progress.ProgressStages.Unspecified"
OS_BOOT_PCI = STATE_DBUS_BASE + "Boot.Progress.ProgressStages.PCIInit"
OS_BOOT_SECPCI = (
    STATE_DBUS_BASE + "Boot.Progress.ProgressStages.SecondaryProcInit"
)
OS_BOOT_MEM = STATE_DBUS_BASE + "Boot.Progress.ProgressStages.MemoryInit"
OS_BOOT_MOTHERBOARD = (
    STATE_DBUS_BASE + "Boot.Progress.ProgressStages.MotherboardInit"
)
OPENBMC_DBUS_BMC_STATE = STATE_DBUS_BASE + "BMC"

# OperatingSystem status variables.
OS_BOOT_COMPLETE = (
    STATE_DBUS_BASE + "OperatingSystem.Status.OSStatus.BootComplete"
)
OS_BOOT_CDROM = STATE_DBUS_BASE + "OperatingSystem.Status.OSStatus.CDROMBoot"
OS_BOOT_ROM = STATE_DBUS_BASE + "OperatingSystem.Status.OSStatus.ROMBoot"
OS_BOOT_PXE = STATE_DBUS_BASE + "OperatingSystem.Status.OSStatus.PXEBoot"
OS_BOOT_CBOOT = STATE_DBUS_BASE + "OperatingSystem.Status.OSStatus.CBoot"
OS_BOOT_DIAGBOOT = STATE_DBUS_BASE + "OperatingSystem.Status.OSStatus.DiagBoot"

# Boot variables.
BOOT_SOURCE_DEFAULT = "xyz.openbmc_project.Control.Boot.Source.Sources.Default"
BOOT_SOURCE_NETWORK = "xyz.openbmc_project.Control.Boot.Source.Sources.Network"
BOOT_SOURCE_DISK = "xyz.openbmc_project.Control.Boot.Source.Sources.Disk"
BOOT_SOURCE_CDROM = (
    "xyz.openbmc_project.Control.Boot.Source.Sources.ExternalMedia"
)
BOOT_MODE_SAFE = "xyz.openbmc_project.Control.Boot.Mode.Modes.Safe"
BOOT_MODE_SETUP = "xyz.openbmc_project.Control.Boot.Mode.Modes.Setup"
BOOT_MODE_REGULAR = "xyz.openbmc_project.Control.Boot.Mode.Modes.Regular"
BOOT_TYPE_LEGACY = "xyz.openbmc_project.Control.Boot.Type.Types.Legacy"
BOOT_TYPE_EFI = "xyz.openbmc_project.Control.Boot.Type.Types.EFI"

# Time variables.
TIME_DBUS_BASE = "xyz.openbmc_project.Time."
BMC_OWNER = TIME_DBUS_BASE + "Owner.Owners.BMC"
HOST_OWNER = TIME_DBUS_BASE + "Owner.Owners.Host"
SPLIT_OWNER = TIME_DBUS_BASE + "Owner.Owners.Split"
BOTH_OWNER = TIME_DBUS_BASE + "Owner.Owners.Both"
NTP_MODE = TIME_DBUS_BASE + "Synchronization.Method.NTP"
MANUAL_MODE = TIME_DBUS_BASE + "Synchronization.Method.Manual"

# User manager variable.
BMC_USER_URI = OPENBMC_BASE_URI + "user/"

# LDAP User manager variable.
BMC_LDAP_URI = BMC_USER_URI + "ldap"

# The path on the BMC where signed keys are stored.
ACTIVATION_DIR_PATH = "/etc/activationdata/"

# Redfish variables.
REDFISH_BASE_URI = "/redfish/v1/"
REDFISH_SESSION = REDFISH_BASE_URI + "SessionService/Sessions"
REDFISH_SESSION_URI = "SessionService/Sessions/"
REDFISH_MANAGERS_ID = BuiltIn().get_variable_value(
    "${MANAGER_ID}", default="bmc"
)
REDFISH_NW_ETH0 = (
    "Managers/" + REDFISH_MANAGERS_ID + "/EthernetInterfaces/eth0/"
)
REDFISH_NW_ETH0_URI = REDFISH_BASE_URI + REDFISH_NW_ETH0
REDFISH_NW_ETH_IFACE = (
    REDFISH_BASE_URI
    + "Managers/"
    + REDFISH_MANAGERS_ID
    + "/EthernetInterfaces/"
)
REDFISH_LLDP_ETH_IFACE = (
    REDFISH_BASE_URI
    + "Managers/"
    + REDFISH_MANAGERS_ID
    + "/DedicatedNetworkPorts/"
)
REDFISH_NW_PROTOCOL = "Managers/" + REDFISH_MANAGERS_ID + "/NetworkProtocol"
REDFISH_NW_PROTOCOL_URI = REDFISH_BASE_URI + REDFISH_NW_PROTOCOL
REDFISH_ACCOUNTS_SERVICE = "AccountService/"
REDFISH_ACCOUNTS_SERVICE_URI = REDFISH_BASE_URI + REDFISH_ACCOUNTS_SERVICE
REDFISH_ACCOUNTS = "AccountService/Accounts/"
REDFISH_ACCOUNTS_URI = REDFISH_BASE_URI + REDFISH_ACCOUNTS
REDFISH_HTTPS_CERTIFICATE = (
    "Managers/" + REDFISH_MANAGERS_ID + "/NetworkProtocol/HTTPS/Certificates"
)
REDFISH_HTTPS_CERTIFICATE_URI = REDFISH_BASE_URI + REDFISH_HTTPS_CERTIFICATE
REDFISH_LDAP_CERTIFICATE = "AccountService/LDAP/Certificates"
REDFISH_LDAP_CERTIFICATE_URI = REDFISH_BASE_URI + REDFISH_LDAP_CERTIFICATE
REDFISH_CA_CERTIFICATE = (
    "Managers/" + REDFISH_MANAGERS_ID + "/Truststore/Certificates"
)
REDFISH_CA_CERTIFICATE_URI = REDFISH_BASE_URI + REDFISH_CA_CERTIFICATE
REDFISH_CHASSIS_ID = BuiltIn().get_variable_value(
    "${CHASSIS_ID}", default="chassis"
)
REDFISH_CHASSIS_URI = REDFISH_BASE_URI + "Chassis/"
REDFISH_CHASSIS_THERMAL = REDFISH_CHASSIS_ID + "/Thermal/"
REDFISH_CHASSIS_THERMAL_URI = REDFISH_CHASSIS_URI + REDFISH_CHASSIS_THERMAL
REDFISH_CHASSIS_POWER = REDFISH_CHASSIS_ID + "/Power/"
REDFISH_CHASSIS_POWER_URI = REDFISH_CHASSIS_URI + REDFISH_CHASSIS_POWER
REDFISH_CHASSIS_SENSORS = REDFISH_CHASSIS_ID + "/Sensors"
REDFISH_CHASSIS_SENSORS_URI = REDFISH_CHASSIS_URI + REDFISH_CHASSIS_SENSORS
REDFISH_BMC_DUMP = (
    "Managers/" + REDFISH_MANAGERS_ID + "/LogServices/Dump/Entries"
)
REDFISH_DUMP_URI = REDFISH_BASE_URI + REDFISH_BMC_DUMP
REDFISH_SYSTEM_DUMP = (
    REDFISH_BASE_URI
    + "/Systems/"
    + REDFISH_SYSTEM_ID
    + "/LogServices/Dump/Entries"
)

# Boot options and URI variables.
POWER_ON = "On"
POWER_GRACEFUL_OFF = "GracefulShutdown"
POWER_GRACEFUL_RESTART = "GracefulRestart"
POWER_FORCE_OFF = "ForceOff"

REDFISH_POWER = (
    "Systems/" + REDFISH_SYSTEM_ID + "/Actions/ComputerSystem.Reset"
)
REDFISH_POWER_URI = REDFISH_BASE_URI + REDFISH_POWER

# rsyslog variables.
REMOTE_LOGGING_URI = OPENBMC_BASE_URI + "logging/config/remote/"

# Certificate variables.
SERVER_CERTIFICATE_URI = OPENBMC_BASE_URI + "certs/server/https"
CLIENT_CERTIFICATE_URI = OPENBMC_BASE_URI + "certs/client/ldap"
CA_CERTIFICATE_URI = OPENBMC_BASE_URI + "certs/authority/truststore"

# EventLog variables.
SYSTEM_BASE_URI = REDFISH_BASE_URI + "Systems/" + REDFISH_SYSTEM_ID + "/"
EVENT_LOG_URI = SYSTEM_BASE_URI + "LogServices/EventLog/"
DUMP_URI = SYSTEM_BASE_URI + "LogServices/Dump/"

BIOS_ATTR_URI = SYSTEM_BASE_URI + "Bios"
BIOS_ATTR_SETTINGS_URI = BIOS_ATTR_URI + "/Settings"

"""
  QEMU HTTPS variable:

  By default lib/resource.robot AUTH URI construct is as
  ${AUTH_URI}   https://${OPENBMC_HOST}${AUTH_SUFFIX}
  ${AUTH_SUFFIX} is populated here by default EMPTY else
  the port from the OS environment
"""

AUTH_SUFFIX = ":" + BuiltIn().get_variable_value(
    "${HTTPS_PORT}", os.getenv("HTTPS_PORT", "443")
)

# Here contains a list of valid Properties bases on fru_type after a boot.
INVENTORY_ITEMS = {
    "CPU": [
        "Custom Field 1",
        "Custom Field 2",
        "Custom Field 3",
        "Custom Field 4",
        "Custom Field 5",
        "Custom Field 6",
        "Custom Field 7",
        "Custom Field 8",
        "FRU File ID",
        "Manufacturer",
        "Name",
        "Part Number",
        "Serial Number",
        "fault",
        "fru_type",
        "is_fru",
        "present",
        "version",
    ],
    "DIMM": [
        "Asset Tag",
        "Custom Field 1",
        "Custom Field 2",
        "Custom Field 3",
        "Custom Field 4",
        "Custom Field 5",
        "Custom Field 6",
        "Custom Field 7",
        "Custom Field 8",
        "FRU File ID",
        "Manufacturer",
        "Model Number",
        "Name",
        "Serial Number",
        "Version",
        "fault",
        "fru_type",
        "is_fru",
        "present",
        "version",
    ],
    "MEMORY_BUFFER": [
        "Custom Field 1",
        "Custom Field 2",
        "Custom Field 3",
        "Custom Field 4",
        "Custom Field 5",
        "Custom Field 6",
        "Custom Field 7",
        "Custom Field 8",
        "FRU File ID",
        "Manufacturer",
        "Name",
        "Part Number",
        "Serial Number",
        "fault",
        "fru_type",
        "is_fru",
        "present",
        "version",
    ],
    "FAN": [
        "fault",
        "fru_type",
        "is_fru",
        "present",
        "version",
    ],
    "DAUGHTER_CARD": [
        "Custom Field 1",
        "Custom Field 2",
        "Custom Field 3",
        "Custom Field 4",
        "Custom Field 5",
        "Custom Field 6",
        "Custom Field 7",
        "Custom Field 8",
        "FRU File ID",
        "Manufacturer",
        "Name",
        "Part Number",
        "Serial Number",
        "fault",
        "fru_type",
        "is_fru",
        "present",
        "version",
    ],
    "BMC": [
        "fault",
        "fru_type",
        "is_fru",
        "manufacturer",
        "present",
        "version",
    ],
    "MAIN_PLANAR": [
        "Custom Field 1",
        "Custom Field 2",
        "Custom Field 3",
        "Custom Field 4",
        "Custom Field 5",
        "Custom Field 6",
        "Custom Field 7",
        "Custom Field 8",
        "Part Number",
        "Serial Number",
        "Type",
        "fault",
        "fru_type",
        "is_fru",
        "present",
        "version",
    ],
    "SYSTEM": [
        "Custom Field 1",
        "Custom Field 2",
        "Custom Field 3",
        "Custom Field 4",
        "Custom Field 5",
        "Custom Field 6",
        "Custom Field 7",
        "Custom Field 8",
        "FRU File ID",
        "Manufacturer",
        "Model Number",
        "Name",
        "Serial Number",
        "Version",
        "fault",
        "fru_type",
        "is_fru",
        "present",
        "version",
    ],
    "CORE": [
        "fault",
        "fru_type",
        "is_fru",
        "present",
        "version",
    ],
}
