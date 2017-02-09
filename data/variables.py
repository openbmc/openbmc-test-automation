import os

# Enable when ready with openbmc/openbmc-test-automation#203
# replace with new path /xyz/openbmc_project
OPENBMC_BASE_URI = '/org/openbmc/'
OPENBMC_BASE_DBUS = 'org.openbmc'

# REST URI base endpoint paths
CONTROL_URI = OPENBMC_BASE_URI + 'control/'
SENSORS_URI = OPENBMC_BASE_URI + 'sensors/'
RECORDS_URI = OPENBMC_BASE_URI + 'records/'
BUTTONS_URI = OPENBMC_BASE_URI + 'buttons/'
SETTINGS_URI = OPENBMC_BASE_URI + 'settings/'
WATCHDOG_URI = OPENBMC_BASE_URI + 'watchdog/'
INVENTORY_URI = OPENBMC_BASE_URI + 'inventory/'
USER_MANAGER_URI = OPENBMC_BASE_URI + 'UserManager/'
NETWORK_MANAGER_URI = OPENBMC_BASE_URI + 'NetworkManager/'
TIME_MANAGER_URI = OPENBMC_BASE_URI + 'TimeManager/'

# State Manager base variables.
BMC_REBOOT_TRANS = 'xyz.openbmc_project.State.BMC.Transition.Reboot'

HOST_POWEROFF_TRANS = 'xyz.openbmc_project.State.Host.Transition.Off'
HOST_POWERON_TRANS = 'xyz.openbmc_project.State.Host.Transition.On'
HOST_POWEROFF_STATE = 'xyz.openbmc_project.State.Host.HostState.Off'
HOST_POWERON_STATE = 'xyz.openbmc_project.State.Host.HostState.Running'

CHASSIS_POWEROFF_TRANS = 'xyz.openbmc_project.State.Chassis.Transition.Off'
CHASSIS_POWERON_TRANS = 'xyz.openbmc_project.State.Chassis.Transition.On'
CHASSIS_POWEROFF_STATE = 'xyz.openbmc_project.State.Chassis.PowerState.Off'
CHASSIS_POWERON_STATE = 'xyz.openbmc_project.State.Chassis.PowerState.On'

# State Manager URI variables.
BMC_STATE_URI = '/xyz/openbmc_project/state/BMC0/'
HOST_STATE_URI = '/xyz/openbmc_project/state/host0/'
CHASSIS_STATE_URI = '/xyz/openbmc_project/state/chassis0/'

# Logging URI variables
BMC_LOGGING_URI = '/xyz/openbmc_project/Logging/'
BMC_LOGGING_ENTRY = BMC_LOGGING_URI + 'Entry/'

# Software manager version
SOFTWARE_VERSION_URI = '/xyz/openbmc_project/software/'
ACTIVE = 'xyz.openbmc_project.Software.Activation.Activations.Active'

'''
  QEMU HTTPS variable:

  By default lib/resource.txt AUTH URI construct is as
  ${AUTH_URI}   https://${OPENBMC_HOST}${AUTH_SUFFIX}
  ${AUTH_SUFFIX} is populated here by default EMPTY else
  the port from the OS environment
'''


def get_port_https():
    # defaulted to empty string
    l_suffix = ''
    try:
        l_https_port = os.getenv('HTTPS_PORT')
        if l_https_port:
            l_suffix = ':' + l_https_port
    except:
        print "Environment variable HTTPS_PORT not set,\
              using default HTTPS port"
    return l_suffix

AUTH_SUFFIX = {
    "https_port": [get_port_https()],
}

# Update the ':Port number' to this variable
AUTH_SUFFIX = AUTH_SUFFIX['https_port'][0]

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
