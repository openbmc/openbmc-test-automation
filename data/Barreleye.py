#! /usr/bin/python

HOME_PATH = './'
CACHE_PATH = '/var/cache/obmc/'
FLASH_DOWNLOAD_PATH = "/tmp"
GPIO_BASE = 320
SYSTEM_NAME = "Barreleye"


# System states
# state can change to next state in 2 ways:
# - a process emits a GotoSystemState signal with state name to goto
# - objects specified in EXIT_STATE_DEPEND have started
SYSTEM_STATES = [
    'BASE_APPS',
    'BMC_STARTING',
    'BMC_STARTING2',
    'BMC_READY',
    'HOST_POWERING_ON',
    'HOST_POWERED_ON',
    'HOST_BOOTING',
    'HOST_BOOTED',
    'HOST_POWERED_OFF',
]

EXIT_STATE_DEPEND = {
    'BASE_APPS': {
        '/org/openbmc/sensors': 0,
    },
    'BMC_STARTING': {
        '/org/openbmc/control/power0': 0,
        '/org/openbmc/control/host0': 0,
        '/org/openbmc/control/flash/bios': 0,
        '/org/openbmc/sensors/speed/fan5': 0,
        '/org/openbmc/inventory/system/chassis/io_board': 0,
    },
    'BMC_STARTING2': {
        '/org/openbmc/control/fans': 0,
        '/org/openbmc/control/chassis0': 0,
    },
}

# method will be called when state is entered
ENTER_STATE_CALLBACK = {
    'HOST_POWERED_ON': {
        'boot': {
            'bus_name': 'org.openbmc.control.Host',
            'obj_name': '/org/openbmc/control/host0',
            'interface_name': 'org.openbmc.control.Host',
        },
        'setMax': {
            'bus_name': 'org.openbmc.control.Fans',
            'obj_name': '/org/openbmc/control/fans',
            'interface_name': 'org.openbmc.control.Fans',
        },
        'setOn': {
            'bus_name': 'org.openbmc.control.led',
            'obj_name': '/org/openbmc/control/led/identify',
            'interface_name': 'org.openbmc.Led',
        }
    },
    'HOST_POWERED_OFF': {
        'setOff': {
            'bus_name': 'org.openbmc.control.led',
            'obj_name': '/org/openbmc/control/led/identify',
            'interface_name': 'org.openbmc.Led',
        }

    },
    'BMC_READY': {
        'setOn': {
            'bus_name': 'org.openbmc.control.led',
            'obj_name': '/org/openbmc/control/led/beep',
            'interface_name': 'org.openbmc.Led',
        },
        'init': {
            'bus_name': 'org.openbmc.control.Flash',
            'obj_name': '/org/openbmc/control/flash/bios',
            'interface_name': 'org.openbmc.Flash',
        }
    }
}

APPS = {
    'startup_hacks': {
        'system_state': 'BASE_APPS',
        'start_process': True,
        'monitor_process': False,
        'process_name': 'startup_hacks.sh',
    },
    'inventory': {
        'system_state': 'BMC_STARTING',
        'start_process': True,
        'monitor_process': True,
        'process_name': 'inventory_items.py',
        'args': [SYSTEM_NAME]
    },
    'pcie_present': {
        'system_state': 'HOST_POWERED_ON',
        'start_process': True,
        'monitor_process': False,
        'process_name': 'pcie_slot_present.exe',
    },
    'fan_control': {
        'system_state': 'BMC_STARTING2',
        'start_process': True,
        'monitor_process': True,
        'process_name': 'fan_control.py',
    },
    'hwmon': {
        'system_state': 'BMC_STARTING',
        'start_process': True,
        'monitor_process': True,
        'process_name': 'hwmon.py',
        'args': [SYSTEM_NAME]
    },
    'sensor_manager': {
        'system_state': 'BASE_APPS',
        'start_process': True,
        'monitor_process': True,
        'process_name': 'sensor_manager2.py',
        'args': [SYSTEM_NAME]
    },
    'host_watchdog': {
        'system_state': 'BMC_STARTING',
        'start_process': True,
        'monitor_process': True,
        'process_name': 'host_watchdog.exe',
    },
    'power_control': {
        'system_state': 'BMC_STARTING',
        'start_process': True,
        'monitor_process': True,
        'process_name': 'power_control.exe',
        'args': ['3000', '10']
    },
    'power_button': {
        'system_state': 'BMC_STARTING',
        'start_process': True,
        'monitor_process': True,
        'process_name': 'button_power.exe',
    },
    'reset_button': {
        'system_state': 'BMC_STARTING',
        'start_process': True,
        'monitor_process': True,
        'process_name': 'button_reset.exe',
    },
    'led_control': {
        'system_state': 'BMC_STARTING',
        'start_process': True,
        'monitor_process': True,
        'process_name': 'led_controller.exe',
    },
    'flash_control': {
        'system_state': 'BMC_STARTING',
        'start_process': True,
        'monitor_process': True,
        'process_name': 'flash_bios.exe',
    },
    'bmc_flash_control': {
        'system_state': 'BMC_STARTING',
        'start_process': True,
        'monitor_process': True,
        'process_name': 'bmc_update.py',
    },
    'download_manager': {
        'system_state': 'BMC_STARTING',
        'start_process': True,
        'monitor_process': True,
        'process_name': 'download_manager.py',
        'args': [SYSTEM_NAME]
    },
    'host_control': {
        'system_state': 'BMC_STARTING',
        'start_process': True,
        'monitor_process': True,
        'process_name': 'control_host.exe',
    },
    'chassis_control': {
        'system_state': 'BMC_STARTING2',
        'start_process': True,
        'monitor_process': True,
        'process_name': 'chassis_control.py',
    },
    'board_vpd': {
        'system_state': 'BMC_STARTING2',
        'start_process': True,
        'monitor_process': False,
        'process_name': 'phosphor-read-eeprom',
        'args': ['--eeprom', '/sys/bus/i2c/devices/0-0050/eeprom', '--fruid', '64'],
    },
    'exp_vpd': {
        'system_state': 'BMC_STARTING2',
        'start_process': True,
        'monitor_process': False,
        'process_name': 'phosphor-read-eeprom',
        'args': ['--eeprom', '/sys/bus/i2c/devices/6-0051/eeprom', '--fruid', '65'],
    },
    'hdd_vpd': {
        'system_state': 'BMC_STARTING2',
        'start_process': True,
        'monitor_process': False,
        'process_name': 'phosphor-read-eeprom',
        'args': ['--eeprom', '/sys/bus/i2c/devices/6-0055/eeprom', '--fruid', '66'],
    },
    'restore': {
        'system_state': 'BMC_READY',
        'start_process': True,
        'monitor_process': False,
        'process_name': 'discover_system_state.py',
    },
    'bmc_control': {
        'system_state': 'BMC_STARTING',
        'start_process': True,
        'monitor_process': True,
        'process_name': 'control_bmc.exe',
    },
}

CACHED_INTERFACES = {
    "org.openbmc.InventoryItem": True,
    "org.openbmc.control.Chassis": True,
}
INVENTORY_ROOT = '/org/openbmc/inventory'

FRU_INSTANCES = {
    '<inventory_root>/system': {'fru_type': 'SYSTEM', 'is_fru': True, 'present': "True"},
    '<inventory_root>/system/bios': {'fru_type': 'SYSTEM', 'is_fru': True, 'present': "True"},
    '<inventory_root>/system/misc': {'fru_type': 'SYSTEM', 'is_fru': False, },

    '<inventory_root>/system/chassis': {'fru_type': 'SYSTEM', 'is_fru': True, 'present': "True"},

    '<inventory_root>/system/chassis/motherboard': {'fru_type': 'MAIN_PLANAR', 'is_fru': True, },
    '<inventory_root>/system/chassis/io_board': {'fru_type': 'DAUGHTER_CARD', 'is_fru': True, },
    '<inventory_root>/system/chassis/sas_expander': {'fru_type': 'DAUGHTER_CARD', 'is_fru': True, },
    '<inventory_root>/system/chassis/hdd_backplane': {'fru_type': 'DAUGHTER_CARD', 'is_fru': True, },

    '<inventory_root>/system/systemevent': {'fru_type': 'SYSTEM_EVENT', 'is_fru': False, },
    '<inventory_root>/system/chassis/motherboard/refclock': {'fru_type': 'MAIN_PLANAR', 'is_fru': False, },
    '<inventory_root>/system/chassis/motherboard/pcieclock': {'fru_type': 'MAIN_PLANAR', 'is_fru': False, },
    '<inventory_root>/system/chassis/motherboard/todclock': {'fru_type': 'MAIN_PLANAR', 'is_fru': False, },
    '<inventory_root>/system/chassis/motherboard/apss': {'fru_type': 'MAIN_PLANAR', 'is_fru': False, },

    '<inventory_root>/system/chassis/fan0': {'fru_type': 'FAN', 'is_fru': True, },
    '<inventory_root>/system/chassis/fan1': {'fru_type': 'FAN', 'is_fru': True, },
    '<inventory_root>/system/chassis/fan2': {'fru_type': 'FAN', 'is_fru': True, },
    '<inventory_root>/system/chassis/fan3': {'fru_type': 'FAN', 'is_fru': True, },
    '<inventory_root>/system/chassis/fan4': {'fru_type': 'FAN', 'is_fru': True, },
    '<inventory_root>/system/chassis/fan5': {'fru_type': 'FAN', 'is_fru': True, },

    '<inventory_root>/system/chassis/motherboard/bmc': {'fru_type': 'BMC', 'is_fru': False, 'manufacturer': 'ASPEED'},

    '<inventory_root>/system/chassis/motherboard/cpu0': {'fru_type': 'CPU', 'is_fru': True, },
    '<inventory_root>/system/chassis/motherboard/cpu1': {'fru_type': 'CPU', 'is_fru': True, },

    '<inventory_root>/system/chassis/motherboard/cpu0/core0': {'fru_type': 'CORE', 'is_fru': False, },
    '<inventory_root>/system/chassis/motherboard/cpu0/core1': {'fru_type': 'CORE', 'is_fru': False, },
    '<inventory_root>/system/chassis/motherboard/cpu0/core2': {'fru_type': 'CORE', 'is_fru': False, },
    '<inventory_root>/system/chassis/motherboard/cpu0/core3': {'fru_type': 'CORE', 'is_fru': False, },
    '<inventory_root>/system/chassis/motherboard/cpu0/core4': {'fru_type': 'CORE', 'is_fru': False, },
    '<inventory_root>/system/chassis/motherboard/cpu0/core5': {'fru_type': 'CORE', 'is_fru': False, },
    '<inventory_root>/system/chassis/motherboard/cpu0/core6': {'fru_type': 'CORE', 'is_fru': False, },
    '<inventory_root>/system/chassis/motherboard/cpu0/core7': {'fru_type': 'CORE', 'is_fru': False, },
    '<inventory_root>/system/chassis/motherboard/cpu0/core8': {'fru_type': 'CORE', 'is_fru': False, },
    '<inventory_root>/system/chassis/motherboard/cpu0/core9': {'fru_type': 'CORE', 'is_fru': False, },
    '<inventory_root>/system/chassis/motherboard/cpu0/core10': {'fru_type': 'CORE', 'is_fru': False, },
    '<inventory_root>/system/chassis/motherboard/cpu0/core11': {'fru_type': 'CORE', 'is_fru': False, },

    '<inventory_root>/system/chassis/motherboard/cpu1/core0': {'fru_type': 'CORE', 'is_fru': False, },
    '<inventory_root>/system/chassis/motherboard/cpu1/core1': {'fru_type': 'CORE', 'is_fru': False, },
    '<inventory_root>/system/chassis/motherboard/cpu1/core2': {'fru_type': 'CORE', 'is_fru': False, },
    '<inventory_root>/system/chassis/motherboard/cpu1/core3': {'fru_type': 'CORE', 'is_fru': False, },
    '<inventory_root>/system/chassis/motherboard/cpu1/core4': {'fru_type': 'CORE', 'is_fru': False, },
    '<inventory_root>/system/chassis/motherboard/cpu1/core5': {'fru_type': 'CORE', 'is_fru': False, },
    '<inventory_root>/system/chassis/motherboard/cpu1/core6': {'fru_type': 'CORE', 'is_fru': False, },
    '<inventory_root>/system/chassis/motherboard/cpu1/core7': {'fru_type': 'CORE', 'is_fru': False, },
    '<inventory_root>/system/chassis/motherboard/cpu1/core8': {'fru_type': 'CORE', 'is_fru': False, },
    '<inventory_root>/system/chassis/motherboard/cpu1/core9': {'fru_type': 'CORE', 'is_fru': False, },
    '<inventory_root>/system/chassis/motherboard/cpu1/core10': {'fru_type': 'CORE', 'is_fru': False, },
    '<inventory_root>/system/chassis/motherboard/cpu1/core11': {'fru_type': 'CORE', 'is_fru': False, },

    '<inventory_root>/system/chassis/motherboard/membuf0': {'fru_type': 'MEMORY_BUFFER', 'is_fru': False, },
    '<inventory_root>/system/chassis/motherboard/membuf1': {'fru_type': 'MEMORY_BUFFER', 'is_fru': False, },
    '<inventory_root>/system/chassis/motherboard/membuf2': {'fru_type': 'MEMORY_BUFFER', 'is_fru': False, },
    '<inventory_root>/system/chassis/motherboard/membuf3': {'fru_type': 'MEMORY_BUFFER', 'is_fru': False, },
    '<inventory_root>/system/chassis/motherboard/membuf4': {'fru_type': 'MEMORY_BUFFER', 'is_fru': False, },
    '<inventory_root>/system/chassis/motherboard/membuf5': {'fru_type': 'MEMORY_BUFFER', 'is_fru': False, },
    '<inventory_root>/system/chassis/motherboard/membuf6': {'fru_type': 'MEMORY_BUFFER', 'is_fru': False, },
    '<inventory_root>/system/chassis/motherboard/membuf7': {'fru_type': 'MEMORY_BUFFER', 'is_fru': False, },

    '<inventory_root>/system/chassis/motherboard/dimm0': {'fru_type': 'DIMM', 'is_fru': True, },
    '<inventory_root>/system/chassis/motherboard/dimm1': {'fru_type': 'DIMM', 'is_fru': True, },
    '<inventory_root>/system/chassis/motherboard/dimm2': {'fru_type': 'DIMM', 'is_fru': True, },
    '<inventory_root>/system/chassis/motherboard/dimm3': {'fru_type': 'DIMM', 'is_fru': True, },
    '<inventory_root>/system/chassis/motherboard/dimm4': {'fru_type': 'DIMM', 'is_fru': True, },
    '<inventory_root>/system/chassis/motherboard/dimm5': {'fru_type': 'DIMM', 'is_fru': True, },
    '<inventory_root>/system/chassis/motherboard/dimm6': {'fru_type': 'DIMM', 'is_fru': True, },
    '<inventory_root>/system/chassis/motherboard/dimm7': {'fru_type': 'DIMM', 'is_fru': True, },
    '<inventory_root>/system/chassis/motherboard/dimm8': {'fru_type': 'DIMM', 'is_fru': True, },
    '<inventory_root>/system/chassis/motherboard/dimm9': {'fru_type': 'DIMM', 'is_fru': True, },
    '<inventory_root>/system/chassis/motherboard/dimm10': {'fru_type': 'DIMM', 'is_fru': True, },
    '<inventory_root>/system/chassis/motherboard/dimm11': {'fru_type': 'DIMM', 'is_fru': True, },
    '<inventory_root>/system/chassis/motherboard/dimm12': {'fru_type': 'DIMM', 'is_fru': True, },
    '<inventory_root>/system/chassis/motherboard/dimm13': {'fru_type': 'DIMM', 'is_fru': True, },
    '<inventory_root>/system/chassis/motherboard/dimm14': {'fru_type': 'DIMM', 'is_fru': True, },
    '<inventory_root>/system/chassis/motherboard/dimm15': {'fru_type': 'DIMM', 'is_fru': True, },
    '<inventory_root>/system/chassis/motherboard/dimm16': {'fru_type': 'DIMM', 'is_fru': True, },
    '<inventory_root>/system/chassis/motherboard/dimm17': {'fru_type': 'DIMM', 'is_fru': True, },
    '<inventory_root>/system/chassis/motherboard/dimm18': {'fru_type': 'DIMM', 'is_fru': True, },
    '<inventory_root>/system/chassis/motherboard/dimm19': {'fru_type': 'DIMM', 'is_fru': True, },
    '<inventory_root>/system/chassis/motherboard/dimm20': {'fru_type': 'DIMM', 'is_fru': True, },
    '<inventory_root>/system/chassis/motherboard/dimm21': {'fru_type': 'DIMM', 'is_fru': True, },
    '<inventory_root>/system/chassis/motherboard/dimm22': {'fru_type': 'DIMM', 'is_fru': True, },
    '<inventory_root>/system/chassis/motherboard/dimm23': {'fru_type': 'DIMM', 'is_fru': True, },
    '<inventory_root>/system/chassis/motherboard/dimm24': {'fru_type': 'DIMM', 'is_fru': True, },
    '<inventory_root>/system/chassis/motherboard/dimm25': {'fru_type': 'DIMM', 'is_fru': True, },
    '<inventory_root>/system/chassis/motherboard/dimm26': {'fru_type': 'DIMM', 'is_fru': True, },
    '<inventory_root>/system/chassis/motherboard/dimm27': {'fru_type': 'DIMM', 'is_fru': True, },
    '<inventory_root>/system/chassis/motherboard/dimm28': {'fru_type': 'DIMM', 'is_fru': True, },
    '<inventory_root>/system/chassis/motherboard/dimm29': {'fru_type': 'DIMM', 'is_fru': True, },
    '<inventory_root>/system/chassis/motherboard/dimm30': {'fru_type': 'DIMM', 'is_fru': True, },
    '<inventory_root>/system/chassis/motherboard/dimm31': {'fru_type': 'DIMM', 'is_fru': True, },

    '<inventory_root>/system/chassis/io_board/pcie_slot0_riser': {'fru_type': 'PCIE_RISER', 'is_fru': True, },
    '<inventory_root>/system/chassis/io_board/pcie_slot1_riser': {'fru_type': 'PCIE_RISER', 'is_fru': True, },
    '<inventory_root>/system/chassis/io_board/pcie_slot2_riser': {'fru_type': 'PCIE_RISER', 'is_fru': True, },
    '<inventory_root>/system/chassis/io_board/pcie_slot0': {'fru_type': 'PCIE_CARD', 'is_fru': True, },
    '<inventory_root>/system/chassis/io_board/pcie_slot1':	{'fru_type': 'PCIE_CARD', 'is_fru': True, },
    '<inventory_root>/system/chassis/io_board/pcie_slot2':	{'fru_type': 'PCIE_CARD', 'is_fru': True, },
    '<inventory_root>/system/chassis/io_board/pcie_mezz0':	{'fru_type': 'PCIE_CARD', 'is_fru': True, },
    '<inventory_root>/system/chassis/io_board/pcie_mezz1':	{'fru_type': 'PCIE_CARD', 'is_fru': True, },
}

ID_LOOKUP = {
    'FRU': {
        0x03: '<inventory_root>/system/chassis/motherboard',
        0x40: '<inventory_root>/system/chassis/io_board',
        0x01: '<inventory_root>/system/chassis/motherboard/cpu0',
        0x02: '<inventory_root>/system/chassis/motherboard/cpu1',
        0x04: '<inventory_root>/system/chassis/motherboard/membuf0',
        0x05: '<inventory_root>/system/chassis/motherboard/membuf1',
        0x06: '<inventory_root>/system/chassis/motherboard/membuf2',
        0x07: '<inventory_root>/system/chassis/motherboard/membuf3',
        0x08: '<inventory_root>/system/chassis/motherboard/membuf4',
        0x09: '<inventory_root>/system/chassis/motherboard/membuf5',
        0x0a: '<inventory_root>/system/chassis/motherboard/membuf6',
        0x0b: '<inventory_root>/system/chassis/motherboard/membuf7',
        0x0c: '<inventory_root>/system/chassis/motherboard/dimm0',
        0x0d: '<inventory_root>/system/chassis/motherboard/dimm1',
        0x0e: '<inventory_root>/system/chassis/motherboard/dimm2',
        0x0f: '<inventory_root>/system/chassis/motherboard/dimm3',
        0x10: '<inventory_root>/system/chassis/motherboard/dimm4',
        0x11: '<inventory_root>/system/chassis/motherboard/dimm5',
        0x12: '<inventory_root>/system/chassis/motherboard/dimm6',
        0x13: '<inventory_root>/system/chassis/motherboard/dimm7',
        0x14: '<inventory_root>/system/chassis/motherboard/dimm8',
        0x15: '<inventory_root>/system/chassis/motherboard/dimm9',
        0x16: '<inventory_root>/system/chassis/motherboard/dimm10',
        0x17: '<inventory_root>/system/chassis/motherboard/dimm11',
        0x18: '<inventory_root>/system/chassis/motherboard/dimm12',
        0x19: '<inventory_root>/system/chassis/motherboard/dimm13',
        0x1a: '<inventory_root>/system/chassis/motherboard/dimm14',
        0x1b: '<inventory_root>/system/chassis/motherboard/dimm15',
        0x1c: '<inventory_root>/system/chassis/motherboard/dimm16',
        0x1d: '<inventory_root>/system/chassis/motherboard/dimm17',
        0x1e: '<inventory_root>/system/chassis/motherboard/dimm18',
        0x1f: '<inventory_root>/system/chassis/motherboard/dimm19',
        0x20: '<inventory_root>/system/chassis/motherboard/dimm20',
        0x21: '<inventory_root>/system/chassis/motherboard/dimm21',
        0x22: '<inventory_root>/system/chassis/motherboard/dimm22',
        0x23: '<inventory_root>/system/chassis/motherboard/dimm23',
        0x24: '<inventory_root>/system/chassis/motherboard/dimm24',
        0x25: '<inventory_root>/system/chassis/motherboard/dimm25',
        0x26: '<inventory_root>/system/chassis/motherboard/dimm26',
        0x27: '<inventory_root>/system/chassis/motherboard/dimm27',
        0x28: '<inventory_root>/system/chassis/motherboard/dimm28',
        0x29: '<inventory_root>/system/chassis/motherboard/dimm29',
        0x2a: '<inventory_root>/system/chassis/motherboard/dimm30',
        0x2b: '<inventory_root>/system/chassis/motherboard/dimm31',
        0x33: '<inventory_root>/system',
    },
    'FRU_STR': {
        'PRODUCT_0': '<inventory_root>/system/bios',
        'BOARD_3': '<inventory_root>/system/misc',
        'PRODUCT_51': '<inventory_root>/system/misc',
        'PRODUCT_100': '<inventory_root>/system',
        'CHASSIS_100': '<inventory_root>/system/chassis',
        'BOARD_100': '<inventory_root>/system/chassis/io_board',
        'BOARD_101': '<inventory_root>/system/chassis/sas_expander',
        'BOARD_102': '<inventory_root>/system/chassis/hdd_backplane',
        'CHASSIS_3': '<inventory_root>/system/chassis/motherboard',
        'BOARD_1': '<inventory_root>/system/chassis/motherboard/cpu0',
        'BOARD_2': '<inventory_root>/system/chassis/motherboard/cpu1',
        'BOARD_4': '<inventory_root>/system/chassis/motherboard/membuf0',
        'BOARD_5': '<inventory_root>/system/chassis/motherboard/membuf1',
        'BOARD_6': '<inventory_root>/system/chassis/motherboard/membuf2',
        'BOARD_7': '<inventory_root>/system/chassis/motherboard/membuf3',
        'BOARD_8': '<inventory_root>/system/chassis/motherboard/membuf4',
        'BOARD_9': '<inventory_root>/system/chassis/motherboard/membuf5',
        'BOARD_10': '<inventory_root>/system/chassis/motherboard/membuf6',
        'BOARD_11': '<inventory_root>/system/chassis/motherboard/membuf7',
        'PRODUCT_12': '<inventory_root>/system/chassis/motherboard/dimm0',
        'PRODUCT_13': '<inventory_root>/system/chassis/motherboard/dimm1',
        'PRODUCT_14': '<inventory_root>/system/chassis/motherboard/dimm2',
        'PRODUCT_15': '<inventory_root>/system/chassis/motherboard/dimm3',
        'PRODUCT_16': '<inventory_root>/system/chassis/motherboard/dimm4',
        'PRODUCT_17': '<inventory_root>/system/chassis/motherboard/dimm5',
        'PRODUCT_18': '<inventory_root>/system/chassis/motherboard/dimm6',
        'PRODUCT_19': '<inventory_root>/system/chassis/motherboard/dimm7',
        'PRODUCT_20': '<inventory_root>/system/chassis/motherboard/dimm8',
        'PRODUCT_21': '<inventory_root>/system/chassis/motherboard/dimm9',
        'PRODUCT_22': '<inventory_root>/system/chassis/motherboard/dimm10',
        'PRODUCT_23': '<inventory_root>/system/chassis/motherboard/dimm11',
        'PRODUCT_24': '<inventory_root>/system/chassis/motherboard/dimm12',
        'PRODUCT_25': '<inventory_root>/system/chassis/motherboard/dimm13',
        'PRODUCT_26': '<inventory_root>/system/chassis/motherboard/dimm14',
        'PRODUCT_27': '<inventory_root>/system/chassis/motherboard/dimm15',
        'PRODUCT_28': '<inventory_root>/system/chassis/motherboard/dimm16',
        'PRODUCT_29': '<inventory_root>/system/chassis/motherboard/dimm17',
        'PRODUCT_30': '<inventory_root>/system/chassis/motherboard/dimm18',
        'PRODUCT_31': '<inventory_root>/system/chassis/motherboard/dimm19',
        'PRODUCT_32': '<inventory_root>/system/chassis/motherboard/dimm20',
        'PRODUCT_33': '<inventory_root>/system/chassis/motherboard/dimm21',
        'PRODUCT_34': '<inventory_root>/system/chassis/motherboard/dimm22',
        'PRODUCT_35': '<inventory_root>/system/chassis/motherboard/dimm23',
        'PRODUCT_36': '<inventory_root>/system/chassis/motherboard/dimm24',
        'PRODUCT_37': '<inventory_root>/system/chassis/motherboard/dimm25',
        'PRODUCT_38': '<inventory_root>/system/chassis/motherboard/dimm26',
        'PRODUCT_39': '<inventory_root>/system/chassis/motherboard/dimm27',
        'PRODUCT_40': '<inventory_root>/system/chassis/motherboard/dimm28',
        'PRODUCT_41': '<inventory_root>/system/chassis/motherboard/dimm29',
        'PRODUCT_42': '<inventory_root>/system/chassis/motherboard/dimm30',
        'PRODUCT_43': '<inventory_root>/system/chassis/motherboard/dimm31',
    },
    'SENSOR': {
        0x35: '<inventory_root>/system/systemevent',
        0x36: '<inventory_root>/system/powerlimit',
        0x34: '<inventory_root>/system/chassis/motherboard',
        0x31: '<inventory_root>/system/chassis/motherboard/pcielink',
        0x37: '<inventory_root>/system/chassis/motherboard/refclock',
        0x38: '<inventory_root>/system/chassis/motherboard/pcieclock',
        0x39: '<inventory_root>/system/chassis/motherboard/todclock',
        0x3A: '<inventory_root>/system/chassis/motherboard/apss',
        0x0c: '<inventory_root>/system/chassis/motherboard/cpu0',
        0x0e: '<inventory_root>/system/chassis/motherboard/cpu1',
        0xc8: '<inventory_root>/system/chassis/motherboard/cpu0/core0',
        0xc9: '<inventory_root>/system/chassis/motherboard/cpu0/core1',
        0xca: '<inventory_root>/system/chassis/motherboard/cpu0/core2',
        0xcb: '<inventory_root>/system/chassis/motherboard/cpu0/core3',
        0xcc: '<inventory_root>/system/chassis/motherboard/cpu0/core4',
        0xcd: '<inventory_root>/system/chassis/motherboard/cpu0/core5',
        0xce: '<inventory_root>/system/chassis/motherboard/cpu0/core6',
        0xcf: '<inventory_root>/system/chassis/motherboard/cpu0/core7',
        0xd0: '<inventory_root>/system/chassis/motherboard/cpu0/core8',
        0xd1: '<inventory_root>/system/chassis/motherboard/cpu0/core9',
        0xd2: '<inventory_root>/system/chassis/motherboard/cpu0/core10',
        0xd3: '<inventory_root>/system/chassis/motherboard/cpu0/core11',
        0xd4: '<inventory_root>/system/chassis/motherboard/cpu1/core0',
        0xd5: '<inventory_root>/system/chassis/motherboard/cpu1/core1',
        0xd6: '<inventory_root>/system/chassis/motherboard/cpu1/core2',
        0xd7: '<inventory_root>/system/chassis/motherboard/cpu1/core3',
        0xd8: '<inventory_root>/system/chassis/motherboard/cpu1/core4',
        0xd9: '<inventory_root>/system/chassis/motherboard/cpu1/core5',
        0xda: '<inventory_root>/system/chassis/motherboard/cpu1/core6',
        0xdb: '<inventory_root>/system/chassis/motherboard/cpu1/core7',
        0xdc: '<inventory_root>/system/chassis/motherboard/cpu1/core8',
        0xdd: '<inventory_root>/system/chassis/motherboard/cpu1/core9',
        0xde: '<inventory_root>/system/chassis/motherboard/cpu1/core10',
        0xdf: '<inventory_root>/system/chassis/motherboard/cpu1/core11',
        0x40: '<inventory_root>/system/chassis/motherboard/membuf0',
        0x41: '<inventory_root>/system/chassis/motherboard/membuf1',
        0x42: '<inventory_root>/system/chassis/motherboard/membuf2',
        0x43: '<inventory_root>/system/chassis/motherboard/membuf3',
        0x44: '<inventory_root>/system/chassis/motherboard/membuf4',
        0x45: '<inventory_root>/system/chassis/motherboard/membuf5',
        0x46: '<inventory_root>/system/chassis/motherboard/membuf6',
        0x47: '<inventory_root>/system/chassis/motherboard/membuf7',
        0x10: '<inventory_root>/system/chassis/motherboard/dimm0',
        0x11: '<inventory_root>/system/chassis/motherboard/dimm1',
        0x12: '<inventory_root>/system/chassis/motherboard/dimm2',
        0x13: '<inventory_root>/system/chassis/motherboard/dimm3',
        0x14: '<inventory_root>/system/chassis/motherboard/dimm4',
        0x15: '<inventory_root>/system/chassis/motherboard/dimm5',
        0x16: '<inventory_root>/system/chassis/motherboard/dimm6',
        0x17: '<inventory_root>/system/chassis/motherboard/dimm7',
        0x18: '<inventory_root>/system/chassis/motherboard/dimm8',
        0x19: '<inventory_root>/system/chassis/motherboard/dimm9',
        0x1a: '<inventory_root>/system/chassis/motherboard/dimm10',
        0x1b: '<inventory_root>/system/chassis/motherboard/dimm11',
        0x1c: '<inventory_root>/system/chassis/motherboard/dimm12',
        0x1d: '<inventory_root>/system/chassis/motherboard/dimm13',
        0x1e: '<inventory_root>/system/chassis/motherboard/dimm14',
        0x1f: '<inventory_root>/system/chassis/motherboard/dimm15',
        0x20: '<inventory_root>/system/chassis/motherboard/dimm16',
        0x21: '<inventory_root>/system/chassis/motherboard/dimm17',
        0x22: '<inventory_root>/system/chassis/motherboard/dimm18',
        0x23: '<inventory_root>/system/chassis/motherboard/dimm19',
        0x24: '<inventory_root>/system/chassis/motherboard/dimm20',
        0x25: '<inventory_root>/system/chassis/motherboard/dimm21',
        0x26: '<inventory_root>/system/chassis/motherboard/dimm22',
        0x27: '<inventory_root>/system/chassis/motherboard/dimm23',
        0x28: '<inventory_root>/system/chassis/motherboard/dimm24',
        0x29: '<inventory_root>/system/chassis/motherboard/dimm25',
        0x2a: '<inventory_root>/system/chassis/motherboard/dimm26',
        0x2b: '<inventory_root>/system/chassis/motherboard/dimm27',
        0x2c: '<inventory_root>/system/chassis/motherboard/dimm28',
        0x2d: '<inventory_root>/system/chassis/motherboard/dimm29',
        0x2e: '<inventory_root>/system/chassis/motherboard/dimm30',
        0x2f: '<inventory_root>/system/chassis/motherboard/dimm31',
        0x09: '/org/openbmc/sensors/host/BootCount',
        0x05: '/org/openbmc/sensors/host/BootProgress',
        0x04: '/org/openbmc/sensors/host/HostStatus',
        0x08: '/org/openbmc/sensors/host/cpu0/OccStatus',
        0x0A: '/org/openbmc/sensors/host/cpu1/OccStatus',
        0x32: '/org/openbmc/sensors/host/OperatingSystemStatus',
        0x33: '/org/openbmc/sensors/host/powercap',
    },
    'GPIO_PRESENT': {
        'SLOT0_RISER_PRESENT': '<inventory_root>/system/chassis/io_board/pcie_slot0_riser',
        'SLOT1_RISER_PRESENT': '<inventory_root>/system/chassis/io_board/pcie_slot1_riser',
        'SLOT2_RISER_PRESENT': '<inventory_root>/system/chassis/io_board/pcie_slot2_riser',
        'SLOT0_PRESENT': '<inventory_root>/system/chassis/io_board/pcie_slot0',
        'SLOT1_PRESENT': '<inventory_root>/system/chassis/io_board/pcie_slot1',
        'SLOT2_PRESENT': '<inventory_root>/system/chassis/io_board/pcie_slot2',
        'MEZZ0_PRESENT': '<inventory_root>/system/chassis/io_board/pcie_mezz0',
        'MEZZ1_PRESENT': '<inventory_root>/system/chassis/io_board/pcie_mezz1',
    }
}

GPIO_CONFIG = {}
GPIO_CONFIG['FSI_CLK'] = {'gpio_pin': 'A4', 'direction': 'out'}
GPIO_CONFIG['FSI_DATA'] = {'gpio_pin': 'A5', 'direction': 'out'}
GPIO_CONFIG['FSI_ENABLE'] = {'gpio_pin': 'D0', 'direction': 'out'}
GPIO_CONFIG['POWER_PIN'] = {'gpio_pin': 'E1', 'direction': 'out'}
GPIO_CONFIG['CRONUS_SEL'] = {'gpio_pin': 'A6', 'direction': 'out'}
GPIO_CONFIG['PGOOD'] = {'gpio_pin': 'C7', 'direction': 'in'}
GPIO_CONFIG['POWER_BUTTON'] = {'gpio_pin': 'E0', 'direction': 'both'}
GPIO_CONFIG['PCIE_RESET'] = {'gpio_pin': 'B5', 'direction': 'out'}
GPIO_CONFIG['USB_RESET'] = {'gpio_pin': 'B6', 'direction': 'out'}

GPIO_CONFIG['IDBTN'] = {'gpio_pin': 'Q7', 'direction': 'out'}
GPIO_CONFIG['BMC_THROTTLE'] = {'gpio_pin': 'J3', 'direction': 'out'}
GPIO_CONFIG['RESET_BUTTON'] = {'gpio_pin': 'E2', 'direction': 'both'}
GPIO_CONFIG['CPLD_TCK'] = {'gpio_pin': 'P0', 'direction': 'out'}
GPIO_CONFIG['CPLD_TDO'] = {'gpio_pin': 'P1', 'direction': 'out'}
GPIO_CONFIG['CPLD_TDI'] = {'gpio_pin': 'P2', 'direction': 'out'}
GPIO_CONFIG['CPLD_TMS'] = {'gpio_pin': 'P3', 'direction': 'out'}

GPIO_CONFIG['SLOT0_RISER_PRESENT'] = {'gpio_pin': 'N0', 'direction': 'in'}
GPIO_CONFIG['SLOT1_RISER_PRESENT'] = {'gpio_pin': 'N1', 'direction': 'in'}
GPIO_CONFIG['SLOT2_RISER_PRESENT'] = {'gpio_pin': 'N2', 'direction': 'in'}
GPIO_CONFIG['SLOT0_PRESENT'] = {'gpio_pin': 'N3', 'direction': 'in'}
GPIO_CONFIG['SLOT1_PRESENT'] = {'gpio_pin': 'N4', 'direction': 'in'}
GPIO_CONFIG['SLOT2_PRESENT'] = {'gpio_pin': 'N5', 'direction': 'in'}
GPIO_CONFIG['MEZZ0_PRESENT'] = {'gpio_pin': 'O0', 'direction': 'in'}
GPIO_CONFIG['MEZZ1_PRESENT'] = {'gpio_pin': 'O1', 'direction': 'in'}


def convertGpio(name):
    name = name.upper()
    c = name[0:1]
    offset = int(name[1:])
    a = ord(c)-65
    base = a*8+GPIO_BASE
    return base+offset


HWMON_CONFIG = {
    '0-004a':  {
        'names': {
            'temp1_input': {'object_path': 'temperature/ambient', 'poll_interval': 5000, 'scale': 1000, 'units': 'C'},
        }
    },
    '6-002d': {
        'names': {
            'pwm1': {'object_path': 'speed/fan0', 'poll_interval': 10000, 'scale': 1, 'units': ''},
            'pwm2': {'object_path': 'speed/fan1', 'poll_interval': 10000, 'scale': 1, 'units': ''},
            'pwm3': {'object_path': 'speed/fan2', 'poll_interval': 10000, 'scale': 1, 'units': ''},
            'in1_input': {'object_path': 'voltage/P1V35_CPU0_BUF4', 'poll_interval': 10000, 'scale': 1, 'units': ''},
            'in2_input': {'object_path': 'voltage/P0V9_CPU0_BUF1', 'poll_interval': 10000, 'scale': 1, 'units': ''},
            'in3_input': {'object_path': 'voltage/P0V9_CPU0_BUF2', 'poll_interval': 10000, 'scale': 1, 'units': ''},
            'in4_input': {'object_path': 'voltage/P0V9_CPU0_BUF3', 'poll_interval': 10000, 'scale': 1, 'units': ''},
            'in5_input': {'object_path': 'voltage/P0V9_CPU0_BUF4', 'poll_interval': 10000, 'scale': 1, 'units': ''},
            'in6_input': {'object_path': 'voltage/P1V09_CPU0_BUF1', 'poll_interval': 10000, 'scale': 1, 'units': ''},
            'in7_input': {'object_path': 'voltage/P1V09_CPU0_BUF2', 'poll_interval': 10000, 'scale': 1, 'units': ''},
            'in8_input': {'object_path': 'voltage/P1V09_CPU0_BUF3', 'poll_interval': 10000, 'scale': 1, 'units': ''},
            'in9_input': {'object_path': 'voltage/P1V09_CPU0_BUF4', 'poll_interval': 10000, 'scale': 1, 'units': ''},
            'in10_input': {'object_path': 'voltage/P0V97_CPU0', 'poll_interval': 10000, 'scale': 1, 'units': ''},
            'in11_input': {'object_path': 'voltage/P1V1_MEM0', 'poll_interval': 10000, 'scale': 1, 'units': ''},
            'in12_input': {'object_path': 'voltage/P1V35_CPU0_BUF1', 'poll_interval': 10000, 'scale': 1, 'units': ''},
            'in13_input': {'object_path': 'voltage/P1V35_CPU0_BUF2', 'poll_interval': 10000, 'scale': 1, 'units': ''},
            'in14_input': {'object_path': 'voltage/P1V35_CPU0_BUF3', 'poll_interval': 10000, 'scale': 1, 'units': ''},
        }
    },
    '6-002e': {
        'names': {
            'pwm1': {'object_path': 'speed/fan3', 'poll_interval': 10000, 'scale': 1, 'units': ''},
            'pwm2': {'object_path': 'speed/fan4', 'poll_interval': 10000, 'scale': 1, 'units': ''},
            'pwm3': {'object_path': 'speed/fan5', 'poll_interval': 10000, 'scale': 1, 'units': ''},
            'in1_input': {'object_path': 'voltage/P1V35_CPU1_BUF4', 'poll_interval': 10000, 'scale': 1, 'units': ''},
            'in2_input': {'object_path': 'voltage/P0V9_CPU1_BUF1', 'poll_interval': 10000, 'scale': 1, 'units': ''},
            'in3_input': {'object_path': 'voltage/P0V9_CPU1_BUF2', 'poll_interval': 10000, 'scale': 1, 'units': ''},
            'in4_input': {'object_path': 'voltage/P0V9_CPU1_BUF3', 'poll_interval': 10000, 'scale': 1, 'units': ''},
            'in5_input': {'object_path': 'voltage/P0V9_CPU1_BUF4', 'poll_interval': 10000, 'scale': 1, 'units': ''},
            'in6_input': {'object_path': 'voltage/P1V09_CPU1_BUF1', 'poll_interval': 10000, 'scale': 1, 'units': ''},
            'in7_input': {'object_path': 'voltage/P1V09_CPU1_BUF2', 'poll_interval': 10000, 'scale': 1, 'units': ''},
            'in8_input': {'object_path': 'voltage/P1V09_CPU1_BUF3', 'poll_interval': 10000, 'scale': 1, 'units': ''},
            'in9_input': {'object_path': 'voltage/P1V09_CPU1_BUF4', 'poll_interval': 10000, 'scale': 1, 'units': ''},
            'in10_input': {'object_path': 'voltage/P0V97_CPU1', 'poll_interval': 10000, 'scale': 1, 'units': ''},
            'in11_input': {'object_path': 'voltage/P1V1_MEM1', 'poll_interval': 10000, 'scale': 1, 'units': ''},
            'in12_input': {'object_path': 'voltage/P1V35_CPU1_BUF1', 'poll_interval': 10000, 'scale': 1, 'units': ''},
            'in13_input': {'object_path': 'voltage/P1V35_CPU1_BUF2', 'poll_interval': 10000, 'scale': 1, 'units': ''},
            'in14_input': {'object_path': 'voltage/P1V35_CPU1_BUF3', 'poll_interval': 10000, 'scale': 1, 'units': ''},
        }
    },
    '3-0050': {
        'names': {
            'caps_curr_powercap': {'object_path': 'powercap/curr_cap', 'poll_interval': 10000, 'scale': 1, 'units': 'W'},
            'caps_curr_powerreading': {'object_path': 'powercap/system_power', 'poll_interval': 10000, 'scale': 1, 'units': 'W'},
            'caps_max_powercap': {'object_path': 'powercap/max_cap', 'poll_interval': 10000, 'scale': 1, 'units': 'W'},
            'caps_min_powercap': {'object_path': 'powercap/min_cap', 'poll_interval': 10000, 'scale': 1, 'units': 'W'},
            'caps_norm_powercap': {'object_path': 'powercap/n_cap', 'poll_interval': 10000, 'scale': 1, 'units': 'W'},
            'caps_user_powerlimit': {'object_path': 'powercap/user_cap', 'poll_interval': 10000, 'scale': 1, 'units': 'W'},
        },
        'labels': {
            '176':  {'object_path': 'temperature/cpu0/core0', 'poll_interval': 5000, 'scale': 1000, 'units': 'C',
                     'critical_upper': 100, 'critical_lower': -100, 'warning_upper': 90, 'warning_lower': -99, 'emergency_enabled': True},
            '177':  {'object_path': 'temperature/cpu0/core1', 'poll_interval': 5000, 'scale': 1000, 'units': 'C',
                     'critical_upper': 100, 'critical_lower': -100, 'warning_upper': 90, 'warning_lower': -99, 'emergency_enabled': True},
            '178':  {'object_path': 'temperature/cpu0/core2', 'poll_interval': 5000, 'scale': 1000, 'units': 'C',
                     'critical_upper': 100, 'critical_lower': -100, 'warning_upper': 90, 'warning_lower': -99, 'emergency_enabled': True},
            '179':  {'object_path': 'temperature/cpu0/core3', 'poll_interval': 5000, 'scale': 1000, 'units': 'C',
                     'critical_upper': 100, 'critical_lower': -100, 'warning_upper': 90, 'warning_lower': -99, 'emergency_enabled': True},
            '180':  {'object_path': 'temperature/cpu0/core4', 'poll_interval': 5000, 'scale': 1000, 'units': 'C',
                     'critical_upper': 100, 'critical_lower': -100, 'warning_upper': 90, 'warning_lower': -99, 'emergency_enabled': True},
            '181':  {'object_path': 'temperature/cpu0/core5', 'poll_interval': 5000, 'scale': 1000, 'units': 'C',
                     'critical_upper': 100, 'critical_lower': -100, 'warning_upper': 90, 'warning_lower': -99, 'emergency_enabled': True},
            '182':  {'object_path': 'temperature/cpu0/core6', 'poll_interval': 5000, 'scale': 1000, 'units': 'C',
                     'critical_upper': 100, 'critical_lower': -100, 'warning_upper': 90, 'warning_lower': -99, 'emergency_enabled': True},
            '183':  {'object_path': 'temperature/cpu0/core7', 'poll_interval': 5000, 'scale': 1000, 'units': 'C',
                     'critical_upper': 100, 'critical_lower': -100, 'warning_upper': 90, 'warning_lower': -99, 'emergency_enabled': True},
            '184':  {'object_path': 'temperature/cpu0/core8', 'poll_interval': 5000, 'scale': 1000, 'units': 'C',
                     'critical_upper': 100, 'critical_lower': -100, 'warning_upper': 90, 'warning_lower': -99, 'emergency_enabled': True},
            '185':  {'object_path': 'temperature/cpu0/core9', 'poll_interval': 5000, 'scale': 1000, 'units': 'C',
                     'critical_upper': 100, 'critical_lower': -100, 'warning_upper': 90, 'warning_lower': -99, 'emergency_enabled': True},
            '186':  {'object_path': 'temperature/cpu0/core10', 'poll_interval': 5000, 'scale': 1000, 'units': 'C',
                     'critical_upper': 100, 'critical_lower': -100, 'warning_upper': 90, 'warning_lower': -99, 'emergency_enabled': True},
            '187':  {'object_path': 'temperature/cpu0/core11', 'poll_interval': 5000, 'scale': 1000, 'units': 'C',
                     'critical_upper': 100, 'critical_lower': -100, 'warning_upper': 90, 'warning_lower': -99, 'emergency_enabled': True},
            '102':  {'object_path': 'temperature/dimm0', 'poll_interval': 5000, 'scale': 1000, 'units': 'C'},
            '103':  {'object_path': 'temperature/dimm1', 'poll_interval': 5000, 'scale': 1000, 'units': 'C'},
            '104':  {'object_path': 'temperature/dimm2', 'poll_interval': 5000, 'scale': 1000, 'units': 'C'},
            '105':  {'object_path': 'temperature/dimm3', 'poll_interval': 5000, 'scale': 1000, 'units': 'C'},
            '106':  {'object_path': 'temperature/dimm4', 'poll_interval': 5000, 'scale': 1000, 'units': 'C'},
            '107':  {'object_path': 'temperature/dimm5', 'poll_interval': 5000, 'scale': 1000, 'units': 'C'},
            '108':  {'object_path': 'temperature/dimm6', 'poll_interval': 5000, 'scale': 1000, 'units': 'C'},
            '109':  {'object_path': 'temperature/dimm7', 'poll_interval': 5000, 'scale': 1000, 'units': 'C'},
            '110':  {'object_path': 'temperature/dimm8', 'poll_interval': 5000, 'scale': 1000, 'units': 'C'},
            '111':  {'object_path': 'temperature/dimm9', 'poll_interval': 5000, 'scale': 1000, 'units': 'C'},
            '112':  {'object_path': 'temperature/dimm10', 'poll_interval': 5000, 'scale': 1000, 'units': 'C'},
            '113':  {'object_path': 'temperature/dimm11', 'poll_interval': 5000, 'scale': 1000, 'units': 'C'},
            '114':  {'object_path': 'temperature/dimm12', 'poll_interval': 5000, 'scale': 1000, 'units': 'C'},
            '115':  {'object_path': 'temperature/dimm13', 'poll_interval': 5000, 'scale': 1000, 'units': 'C'},
            '116':  {'object_path': 'temperature/dimm14', 'poll_interval': 5000, 'scale': 1000, 'units': 'C'},
            '117':  {'object_path': 'temperature/dimm15', 'poll_interval': 5000, 'scale': 1000, 'units': 'C'},
            '94':  {'object_path': 'temperature/membuf0', 'poll_interval': 5000, 'scale': 1000, 'units': 'C'},
            '95':  {'object_path': 'temperature/membuf1', 'poll_interval': 5000, 'scale': 1000, 'units': 'C'},
            '96':  {'object_path': 'temperature/membuf2', 'poll_interval': 5000, 'scale': 1000, 'units': 'C'},
            '97':  {'object_path': 'temperature/membuf3', 'poll_interval': 5000, 'scale': 1000, 'units': 'C'},
        }
    },
    '3-0051': {
        'labels':  {
            '188':  {'object_path': 'temperature/cpu1/core0', 'poll_interval': 5000, 'scale': 1000, 'units': 'C',
                     'critical_upper': 100, 'critical_lower': -100, 'warning_upper': 90, 'warning_lower': -99, 'emergency_enabled': True},
            '189':  {'object_path': 'temperature/cpu1/core1', 'poll_interval': 5000, 'scale': 1000, 'units': 'C',
                     'critical_upper': 100, 'critical_lower': -100, 'warning_upper': 90, 'warning_lower': -99, 'emergency_enabled': True},
            '190':  {'object_path': 'temperature/cpu1/core2', 'poll_interval': 5000, 'scale': 1000, 'units': 'C',
                     'critical_upper': 100, 'critical_lower': -100, 'warning_upper': 90, 'warning_lower': -99, 'emergency_enabled': True},
            '191':  {'object_path': 'temperature/cpu1/core3', 'poll_interval': 5000, 'scale': 1000, 'units': 'C',
                     'critical_upper': 100, 'critical_lower': -100, 'warning_upper': 90, 'warning_lower': -99, 'emergency_enabled': True},
            '192':  {'object_path': 'temperature/cpu1/core4', 'poll_interval': 5000, 'scale': 1000, 'units': 'C',
                     'critical_upper': 100, 'critical_lower': -100, 'warning_upper': 90, 'warning_lower': -99, 'emergency_enabled': True},
            '193':  {'object_path': 'temperature/cpu1/core5', 'poll_interval': 5000, 'scale': 1000, 'units': 'C',
                     'critical_upper': 100, 'critical_lower': -100, 'warning_upper': 90, 'warning_lower': -99, 'emergency_enabled': True},
            '194':  {'object_path': 'temperature/cpu1/core6', 'poll_interval': 5000, 'scale': 1000, 'units': 'C',
                     'critical_upper': 100, 'critical_lower': -100, 'warning_upper': 90, 'warning_lower': -99, 'emergency_enabled': True},
            '195':  {'object_path': 'temperature/cpu1/core7', 'poll_interval': 5000, 'scale': 1000, 'units': 'C',
                     'critical_upper': 100, 'critical_lower': -100, 'warning_upper': 90, 'warning_lower': -99, 'emergency_enabled': True},
            '196':  {'object_path': 'temperature/cpu1/core8', 'poll_interval': 5000, 'scale': 1000, 'units': 'C',
                     'critical_upper': 100, 'critical_lower': -100, 'warning_upper': 90, 'warning_lower': -99, 'emergency_enabled': True},
            '197':  {'object_path': 'temperature/cpu1/core9', 'poll_interval': 5000, 'scale': 1000, 'units': 'C',
                     'critical_upper': 100, 'critical_lower': -100, 'warning_upper': 90, 'warning_lower': -99, 'emergency_enabled': True},
            '198':  {'object_path': 'temperature/cpu1/core10', 'poll_interval': 5000, 'scale': 1000, 'units': 'C',
                     'critical_upper': 100, 'critical_lower': -100, 'warning_upper': 90, 'warning_lower': -99, 'emergency_enabled': True},
            '199':  {'object_path': 'temperature/cpu1/core11', 'poll_interval': 5000, 'scale': 1000, 'units': 'C',
                     'critical_upper': 100, 'critical_lower': -100, 'warning_upper': 90, 'warning_lower': -99, 'emergency_enabled': True},
            '118':  {'object_path': 'temperature/dimm16', 'poll_interval': 5000, 'scale': 1000, 'units': 'C'},
            '119':  {'object_path': 'temperature/dimm17', 'poll_interval': 5000, 'scale': 1000, 'units': 'C'},
            '120':  {'object_path': 'temperature/dimm18', 'poll_interval': 5000, 'scale': 1000, 'units': 'C'},
            '121':  {'object_path': 'temperature/dimm19', 'poll_interval': 5000, 'scale': 1000, 'units': 'C'},
            '122':  {'object_path': 'temperature/dimm20', 'poll_interval': 5000, 'scale': 1000, 'units': 'C'},
            '123':  {'object_path': 'temperature/dimm21', 'poll_interval': 5000, 'scale': 1000, 'units': 'C'},
            '124':  {'object_path': 'temperature/dimm22', 'poll_interval': 5000, 'scale': 1000, 'units': 'C'},
            '125':  {'object_path': 'temperature/dimm23', 'poll_interval': 5000, 'scale': 1000, 'units': 'C'},
            '126':  {'object_path': 'temperature/dimm24', 'poll_interval': 5000, 'scale': 1000, 'units': 'C'},
            '127':  {'object_path': 'temperature/dimm25', 'poll_interval': 5000, 'scale': 1000, 'units': 'C'},
            '128':  {'object_path': 'temperature/dimm26', 'poll_interval': 5000, 'scale': 1000, 'units': 'C'},
            '129':  {'object_path': 'temperature/dimm27', 'poll_interval': 5000, 'scale': 1000, 'units': 'C'},
            '130':  {'object_path': 'temperature/dimm28', 'poll_interval': 5000, 'scale': 1000, 'units': 'C'},
            '131':  {'object_path': 'temperature/dimm29', 'poll_interval': 5000, 'scale': 1000, 'units': 'C'},
            '132':  {'object_path': 'temperature/dimm30', 'poll_interval': 5000, 'scale': 1000, 'units': 'C'},
            '133':  {'object_path': 'temperature/dimm31', 'poll_interval': 5000, 'scale': 1000, 'units': 'C'},
            '98':  {'object_path': 'temperature/membuf4', 'poll_interval': 5000, 'scale': 1000, 'units': 'C'},
            '99':  {'object_path': 'temperature/membuf5', 'poll_interval': 5000, 'scale': 1000, 'units': 'C'},
            '100':  {'object_path': 'temperature/membuf6', 'poll_interval': 5000, 'scale': 1000, 'units': 'C'},
            '101':  {'object_path': 'temperature/membuf7', 'poll_interval': 5000, 'scale': 1000, 'units': 'C'},
        }
    },
    '4-0010':  {
        'names': {
            # Barreleye uses 0.25 millioohms sense resistor for adm1278
            # To convert Iout register value Y to real-world value X, use an equation:
            # X= 1/m * (Y * 10^-R - b), here m = 800 * R_sense, and R_sense is expressed in milliohms.
            # The adm1278 driver did the conversion, but the R_sense is set here as a scale factor.
            'curr1_input': {'object_path': 'HSCA/Iout', 'poll_interval': 5000, 'scale': 0.25, 'units': 'mA'},
            'in2_input': {'object_path': 'HSCA/Vout', 'poll_interval': 5000, 'scale': 1, 'units': 'mV'},
        }
    },
    '5-0010':  {
        'names': {
            'curr1_input': {'object_path': 'HSCB/Iout', 'poll_interval': 5000, 'scale': 0.25, 'units': 'mA'},
            'in2_input': {'object_path': 'HSCB/Vout', 'poll_interval': 5000, 'scale': 1, 'units': 'mV'},
        }
    },
    '6-0010':  {
        'names': {
            'curr1_input': {'object_path': 'HSCC/Iout', 'poll_interval': 5000, 'scale': 0.25, 'units': 'mA'},
            'in2_input': {'object_path': 'HSCC/Vout', 'poll_interval': 5000, 'scale': 1, 'units': 'mV'},
        }
    },
}

# Miscellaneous non-poll sensor with system specific properties.
# The sensor id is the same as those defined in ID_LOOKUP['SENSOR'].
MISC_SENSORS = {
    0x09: {'class': 'BootCountSensor'},
    0x05: {'class': 'BootProgressSensor'},
    0x08: {'class': 'OccStatusSensor',
           'os_path': '/sys/class/i2c-adapter/i2c-3/3-0050/online'},
    0x0A: {'class': 'OccStatusSensor',
           'os_path': '/sys/class/i2c-adapter/i2c-3/3-0051/online'},
    0x32: {'class': 'OperatingSystemStatusSensor'},
    0x33: {'class': 'PowerCap',
           'os_path': '/sys/class/hwmon/hwmon3/user_powercap'},
}
