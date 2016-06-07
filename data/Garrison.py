#! /usr/bin/python

HOME_PATH = './'
CACHE_PATH = '/var/cache/obmc/'
FLASH_DOWNLOAD_PATH = "/tmp"
GPIO_BASE = 320
SYSTEM_NAME = "Garrison"


## System states
##   state can change to next state in 2 ways:
##   - a process emits a GotoSystemState signal with state name to goto
##   - objects specified in EXIT_STATE_DEPEND have started
SYSTEM_STATES = [
    'BASE_APPS',
    'BMC_STARTING',
    'BMC_READY',
    'HOST_POWERING_ON',
    'HOST_POWERED_ON',
    'HOST_BOOTING',
    'HOST_BOOTED',
    'HOST_POWERED_OFF',
]

EXIT_STATE_DEPEND = {
    'BASE_APPS' : {
        '/org/openbmc/sensors': 0,
    },
    'BMC_STARTING' : {
        '/org/openbmc/control/chassis0': 0,
        '/org/openbmc/control/power0' : 0,
        '/org/openbmc/control/host0' : 0,
        '/org/openbmc/control/flash/bios' : 0,
    },
}

## method will be called when state is entered
ENTER_STATE_CALLBACK = {
    'HOST_POWERED_ON' : {
        'boot' : {
            'bus_name'    : 'org.openbmc.control.Host',
            'obj_name'    : '/org/openbmc/control/host0',
            'interface_name' : 'org.openbmc.control.Host',
        },
    },
    'HOST_POWERED_OFF' : {
        'setOff' : {
            'bus_name'   : 'org.openbmc.control.led',
            'obj_name'   : '/org/openbmc/control/led/identify',
            'interface_name' : 'org.openbmc.Led',
        }
    },
    'BMC_READY' : {
        'setOn' : {
            'bus_name'   : 'org.openbmc.control.led',
            'obj_name'   : '/org/openbmc/control/led/beep',
            'interface_name' : 'org.openbmc.Led',
        },
        'init' : {
            'bus_name'   : 'org.openbmc.control.Flash',
            'obj_name'   : '/org/openbmc/control/flash/bios',
            'interface_name' : 'org.openbmc.Flash',
        }
    }
}

APPS = {
    'startup_hacks' : {
        'system_state'    : 'BASE_APPS',
        'start_process'   : True,
        'monitor_process' : False,
        'process_name'    : 'startup_hacks.sh',
    },
    'inventory' : {
        'system_state'    : 'BMC_STARTING',
        'start_process'   : True,
        'monitor_process' : True,
        'process_name'    : 'inventory_items.py',
        'args'            : [ SYSTEM_NAME ]
    },
    'hwmon' : {
        'system_state'    : 'BMC_STARTING',
        'start_process'   : True,
        'monitor_process' : True,
        'process_name'    : 'hwmon.py',
        'args'            : [ SYSTEM_NAME ]
    },
    'sensor_manager' : {
        'system_state'    : 'BASE_APPS',
        'start_process'   : True,
        'monitor_process' : True,
        'process_name'    : 'sensor_manager2.py',
        'args'            : [ SYSTEM_NAME ]
    },
    'host_watchdog' : {
        'system_state'    : 'BMC_STARTING',
        'start_process'   : True,
        'monitor_process' : True,
        'process_name'    : 'host_watchdog.exe',
    },
    'power_control' : {
        'system_state'    : 'BMC_STARTING',
        'start_process'   : True,
        'monitor_process' : True,
        'process_name' : 'power_control.exe',
        'args' : [ '3000', '10' ]
    },
    'power_button' : {
        'system_state'    : 'BMC_STARTING',
        'start_process'   : True,
        'monitor_process' : True,
        'process_name'    : 'button_power.exe',
    },
    'reset_button' : {
        'system_state'    : 'BMC_STARTING',
        'start_process'   : True,
        'monitor_process' : True,
        'process_name'    : 'button_reset.exe',
    },
    'led_control' : {
        'system_state'    : 'BMC_STARTING',
        'start_process'   : True,
        'monitor_process' : True,
        'process_name'    : 'led_controller.exe',
    },
    'flash_control' : {
        'system_state'    : 'BMC_STARTING',
        'start_process'   : True,
        'monitor_process' : True,
        'process_name'    : 'flash_bios.exe',
    },
    'bmc_flash_control' : {
        'system_state'    : 'BMC_STARTING',
        'start_process'   : True,
        'monitor_process' : True,
        'process_name'    : 'bmc_update.py',
    },
    'download_manager' : {
        'system_state'    : 'BMC_STARTING',
        'start_process'   : True,
        'monitor_process' : True,
        'process_name'    : 'download_manager.py',
        'args'            : [ SYSTEM_NAME ]
    },
    'host_control' : {
        'system_state'    : 'BMC_STARTING',
        'start_process'   : True,
        'monitor_process' : True,
        'process_name'    : 'control_host.exe',
    },
    'chassis_control' : {
        'system_state'    : 'BMC_STARTING',
        'start_process'   : True,
        'monitor_process' : True,
        'process_name'    : 'chassis_control.py',
    },
    'restore' : {
        'system_state'    : 'BMC_READY',
        'start_process'   : True,
        'monitor_process' : False,
        'process_name'    : 'discover_system_state.py',
    },
    'bmc_control' : {
        'system_state'    : 'BMC_STARTING',
        'start_process'   : True,
        'monitor_process' : True,
        'process_name'    : 'control_bmc.exe',
    },
}

CACHED_INTERFACES = {
        "org.openbmc.InventoryItem" : True,
        "org.openbmc.control.Chassis" : True,
}

INVENTORY_ROOT = '/org/openbmc/inventory'

FRU_INSTANCES = {
    '<inventory_root>/system' : { 'fru_type' : 'SYSTEM','is_fru' : True, 'present' : "True" },
    '<inventory_root>/system/bios' : { 'fru_type' : 'SYSTEM','is_fru' : True, 'present' : "True" },
    '<inventory_root>/system/misc' : { 'fru_type' : 'SYSTEM','is_fru' : False, },

    '<inventory_root>/system/chassis' : { 'fru_type' : 'SYSTEM','is_fru' : True, 'present' : "True" },

    '<inventory_root>/system/chassis/motherboard' : { 'fru_type' : 'MAIN_PLANAR','is_fru' : True, },

    '<inventory_root>/system/systemevent'                  : { 'fru_type' : 'SYSTEM_EVENT', 'is_fru' : False, },
    '<inventory_root>/system/chassis/motherboard/refclock' : { 'fru_type' : 'MAIN_PLANAR', 'is_fru' : False, },
    '<inventory_root>/system/chassis/motherboard/pcieclock': { 'fru_type' : 'MAIN_PLANAR', 'is_fru' : False, },
    '<inventory_root>/system/chassis/motherboard/todclock' : { 'fru_type' : 'MAIN_PLANAR', 'is_fru' : False, },
    '<inventory_root>/system/chassis/motherboard/apss'     : { 'fru_type' : 'MAIN_PLANAR', 'is_fru' : False, },

    '<inventory_root>/system/chassis/fan0' : { 'fru_type' : 'FAN','is_fru' : True, },
    '<inventory_root>/system/chassis/fan1' : { 'fru_type' : 'FAN','is_fru' : True, },
    '<inventory_root>/system/chassis/fan2' : { 'fru_type' : 'FAN','is_fru' : True, },
    '<inventory_root>/system/chassis/fan3' : { 'fru_type' : 'FAN','is_fru' : True, },

    '<inventory_root>/system/chassis/motherboard/bmc' : { 'fru_type' : 'BMC','is_fru' : False, 'manufacturer' : 'ASPEED' },

    '<inventory_root>/system/chassis/motherboard/cpu0' : { 'fru_type' : 'CPU', 'is_fru' : True, },
    '<inventory_root>/system/chassis/motherboard/cpu1' : { 'fru_type' : 'CPU', 'is_fru' : True, },

    '<inventory_root>/system/chassis/motherboard/cpu0/core0' : { 'fru_type' : 'CORE', 'is_fru' : False, },
    '<inventory_root>/system/chassis/motherboard/cpu0/core1' : { 'fru_type' : 'CORE', 'is_fru' : False, },
    '<inventory_root>/system/chassis/motherboard/cpu0/core2' : { 'fru_type' : 'CORE', 'is_fru' : False, },
    '<inventory_root>/system/chassis/motherboard/cpu0/core3' : { 'fru_type' : 'CORE', 'is_fru' : False, },
    '<inventory_root>/system/chassis/motherboard/cpu0/core4' : { 'fru_type' : 'CORE', 'is_fru' : False, },
    '<inventory_root>/system/chassis/motherboard/cpu0/core5' : { 'fru_type' : 'CORE', 'is_fru' : False, },
    '<inventory_root>/system/chassis/motherboard/cpu0/core6' : { 'fru_type' : 'CORE', 'is_fru' : False, },
    '<inventory_root>/system/chassis/motherboard/cpu0/core7' : { 'fru_type' : 'CORE', 'is_fru' : False, },
    '<inventory_root>/system/chassis/motherboard/cpu0/core8' : { 'fru_type' : 'CORE', 'is_fru' : False, },
    '<inventory_root>/system/chassis/motherboard/cpu0/core9' : { 'fru_type' : 'CORE', 'is_fru' : False, },
    '<inventory_root>/system/chassis/motherboard/cpu0/core10': { 'fru_type' : 'CORE', 'is_fru' : False, },
    '<inventory_root>/system/chassis/motherboard/cpu0/core11': { 'fru_type' : 'CORE', 'is_fru' : False, },

    '<inventory_root>/system/chassis/motherboard/cpu1/core0' : { 'fru_type' : 'CORE', 'is_fru' : False, },
    '<inventory_root>/system/chassis/motherboard/cpu1/core1' : { 'fru_type' : 'CORE', 'is_fru' : False, },
    '<inventory_root>/system/chassis/motherboard/cpu1/core2' : { 'fru_type' : 'CORE', 'is_fru' : False, },
    '<inventory_root>/system/chassis/motherboard/cpu1/core3' : { 'fru_type' : 'CORE', 'is_fru' : False, },
    '<inventory_root>/system/chassis/motherboard/cpu1/core4' : { 'fru_type' : 'CORE', 'is_fru' : False, },
    '<inventory_root>/system/chassis/motherboard/cpu1/core5' : { 'fru_type' : 'CORE', 'is_fru' : False, },
    '<inventory_root>/system/chassis/motherboard/cpu1/core6' : { 'fru_type' : 'CORE', 'is_fru' : False, },
    '<inventory_root>/system/chassis/motherboard/cpu1/core7' : { 'fru_type' : 'CORE', 'is_fru' : False, },
    '<inventory_root>/system/chassis/motherboard/cpu1/core8' : { 'fru_type' : 'CORE', 'is_fru' : False, },
    '<inventory_root>/system/chassis/motherboard/cpu1/core9' : { 'fru_type' : 'CORE', 'is_fru' : False, },
    '<inventory_root>/system/chassis/motherboard/cpu1/core10' : { 'fru_type' : 'CORE', 'is_fru' : False, },
    '<inventory_root>/system/chassis/motherboard/cpu1/core11' : { 'fru_type' : 'CORE', 'is_fru' : False, },

    '<inventory_root>/system/chassis/motherboard/membuf0' : { 'fru_type' : 'MEMORY_BUFFER', 'is_fru' : False, },
    '<inventory_root>/system/chassis/motherboard/membuf1' : { 'fru_type' : 'MEMORY_BUFFER', 'is_fru' : False, },
    '<inventory_root>/system/chassis/motherboard/membuf2' : { 'fru_type' : 'MEMORY_BUFFER', 'is_fru' : False, },
    '<inventory_root>/system/chassis/motherboard/membuf3' : { 'fru_type' : 'MEMORY_BUFFER', 'is_fru' : False, },
    '<inventory_root>/system/chassis/motherboard/membuf4' : { 'fru_type' : 'MEMORY_BUFFER', 'is_fru' : False, },
    '<inventory_root>/system/chassis/motherboard/membuf5' : { 'fru_type' : 'MEMORY_BUFFER', 'is_fru' : False, },
    '<inventory_root>/system/chassis/motherboard/membuf6' : { 'fru_type' : 'MEMORY_BUFFER', 'is_fru' : False, },
    '<inventory_root>/system/chassis/motherboard/membuf7' : { 'fru_type' : 'MEMORY_BUFFER', 'is_fru' : False, },

    '<inventory_root>/system/chassis/motherboard/dimm0' : { 'fru_type' : 'DIMM', 'is_fru' : True,},
    '<inventory_root>/system/chassis/motherboard/dimm1' : { 'fru_type' : 'DIMM', 'is_fru' : True,},
    '<inventory_root>/system/chassis/motherboard/dimm2' : { 'fru_type' : 'DIMM', 'is_fru' : True,},
    '<inventory_root>/system/chassis/motherboard/dimm3' : { 'fru_type' : 'DIMM', 'is_fru' : True,},
    '<inventory_root>/system/chassis/motherboard/dimm4' : { 'fru_type' : 'DIMM', 'is_fru' : True,},
    '<inventory_root>/system/chassis/motherboard/dimm5' : { 'fru_type' : 'DIMM', 'is_fru' : True,},
    '<inventory_root>/system/chassis/motherboard/dimm6' : { 'fru_type' : 'DIMM', 'is_fru' : True,},
    '<inventory_root>/system/chassis/motherboard/dimm7' : { 'fru_type' : 'DIMM', 'is_fru' : True,},
    '<inventory_root>/system/chassis/motherboard/dimm8' : { 'fru_type' : 'DIMM', 'is_fru' : True,},
    '<inventory_root>/system/chassis/motherboard/dimm9' : { 'fru_type' : 'DIMM', 'is_fru' : True,},
    '<inventory_root>/system/chassis/motherboard/dimm10' : { 'fru_type' : 'DIMM', 'is_fru' : True,},
    '<inventory_root>/system/chassis/motherboard/dimm11' : { 'fru_type' : 'DIMM', 'is_fru' : True,},
    '<inventory_root>/system/chassis/motherboard/dimm12' : { 'fru_type' : 'DIMM', 'is_fru' : True,},
    '<inventory_root>/system/chassis/motherboard/dimm13' : { 'fru_type' : 'DIMM', 'is_fru' : True,},
    '<inventory_root>/system/chassis/motherboard/dimm14' : { 'fru_type' : 'DIMM', 'is_fru' : True,},
    '<inventory_root>/system/chassis/motherboard/dimm15' : { 'fru_type' : 'DIMM', 'is_fru' : True,},
    '<inventory_root>/system/chassis/motherboard/dimm16' : { 'fru_type' : 'DIMM', 'is_fru' : True,},
    '<inventory_root>/system/chassis/motherboard/dimm17' : { 'fru_type' : 'DIMM', 'is_fru' : True,},
    '<inventory_root>/system/chassis/motherboard/dimm18' : { 'fru_type' : 'DIMM', 'is_fru' : True,},
    '<inventory_root>/system/chassis/motherboard/dimm19' : { 'fru_type' : 'DIMM', 'is_fru' : True,},
    '<inventory_root>/system/chassis/motherboard/dimm20' : { 'fru_type' : 'DIMM', 'is_fru' : True,},
    '<inventory_root>/system/chassis/motherboard/dimm21' : { 'fru_type' : 'DIMM', 'is_fru' : True,},
    '<inventory_root>/system/chassis/motherboard/dimm22' : { 'fru_type' : 'DIMM', 'is_fru' : True,},
    '<inventory_root>/system/chassis/motherboard/dimm23' : { 'fru_type' : 'DIMM', 'is_fru' : True,},
    '<inventory_root>/system/chassis/motherboard/dimm24' : { 'fru_type' : 'DIMM', 'is_fru' : True,},
    '<inventory_root>/system/chassis/motherboard/dimm25' : { 'fru_type' : 'DIMM', 'is_fru' : True,},
    '<inventory_root>/system/chassis/motherboard/dimm26' : { 'fru_type' : 'DIMM', 'is_fru' : True,},
    '<inventory_root>/system/chassis/motherboard/dimm27' : { 'fru_type' : 'DIMM', 'is_fru' : True,},
    '<inventory_root>/system/chassis/motherboard/dimm28' : { 'fru_type' : 'DIMM', 'is_fru' : True,},
    '<inventory_root>/system/chassis/motherboard/dimm29' : { 'fru_type' : 'DIMM', 'is_fru' : True,},
    '<inventory_root>/system/chassis/motherboard/dimm30' : { 'fru_type' : 'DIMM', 'is_fru' : True,},
    '<inventory_root>/system/chassis/motherboard/dimm31' : { 'fru_type' : 'DIMM', 'is_fru' : True,},
}

ID_LOOKUP = {
    'FRU' : {
        0x01 : '<inventory_root>/system/chassis/motherboard/cpu0',
        0x02 : '<inventory_root>/system/chassis/motherboard/cpu1',
        0x03 : '<inventory_root>/system/chassis/motherboard',
        0x04 : '<inventory_root>/system/chassis/motherboard/membuf0',
        0x05 : '<inventory_root>/system/chassis/motherboard/membuf1',
        0x06 : '<inventory_root>/system/chassis/motherboard/membuf2',
        0x07 : '<inventory_root>/system/chassis/motherboard/membuf3',
        0x08 : '<inventory_root>/system/chassis/motherboard/membuf4',
        0x09 : '<inventory_root>/system/chassis/motherboard/membuf5',
        0x0c : '<inventory_root>/system/chassis/motherboard/dimm0',
        0x0d : '<inventory_root>/system/chassis/motherboard/dimm1',
        0x0e : '<inventory_root>/system/chassis/motherboard/dimm2',
        0x0f : '<inventory_root>/system/chassis/motherboard/dimm3',
        0x10 : '<inventory_root>/system/chassis/motherboard/dimm4',
        0x11 : '<inventory_root>/system/chassis/motherboard/dimm5',
        0x12 : '<inventory_root>/system/chassis/motherboard/dimm6',
        0x13 : '<inventory_root>/system/chassis/motherboard/dimm7',
        0x14 : '<inventory_root>/system/chassis/motherboard/dimm8',
        0x15 : '<inventory_root>/system/chassis/motherboard/dimm9',
        0x16 : '<inventory_root>/system/chassis/motherboard/dimm10',
        0x17 : '<inventory_root>/system/chassis/motherboard/dimm11',
        0x18 : '<inventory_root>/system/chassis/motherboard/dimm12',
        0x19 : '<inventory_root>/system/chassis/motherboard/dimm13',
        0x1a : '<inventory_root>/system/chassis/motherboard/dimm14',
        0x1b : '<inventory_root>/system/chassis/motherboard/dimm15',
        0x1c : '<inventory_root>/system/chassis/motherboard/dimm16',
        0x1d : '<inventory_root>/system/chassis/motherboard/dimm17',
        0x1e : '<inventory_root>/system/chassis/motherboard/dimm18',
        0x1f : '<inventory_root>/system/chassis/motherboard/dimm19',
        0x20 : '<inventory_root>/system/chassis/motherboard/dimm20',
        0x21 : '<inventory_root>/system/chassis/motherboard/dimm21',
        0x22 : '<inventory_root>/system/chassis/motherboard/dimm22',
        0x23 : '<inventory_root>/system/chassis/motherboard/dimm23',
        0x24 : '<inventory_root>/system/chassis/motherboard/dimm24',
        0x25 : '<inventory_root>/system/chassis/motherboard/dimm25',
        0x26 : '<inventory_root>/system/chassis/motherboard/dimm26',
        0x27 : '<inventory_root>/system/chassis/motherboard/dimm27',
        0x28 : '<inventory_root>/system/chassis/motherboard/dimm28',
        0x29 : '<inventory_root>/system/chassis/motherboard/dimm29',
        0x2a : '<inventory_root>/system/chassis/motherboard/dimm30',
        0x2b : '<inventory_root>/system/chassis/motherboard/dimm31',
    },
    'FRU_STR' : {
        'PRODUCT_0'  : '<inventory_root>/system/bios',
        'BOARD_1'    : '<inventory_root>/system/chassis/motherboard/cpu0',
        'BOARD_2'    : '<inventory_root>/system/chassis/motherboard/cpu1',
        'CHASSIS_3'  : '<inventory_root>/system/chassis/motherboard',
        'BOARD_3'    : '<inventory_root>/system/misc',
        'BOARD_4'    : '<inventory_root>/system/chassis/motherboard/membuf0',
        'BOARD_5'    : '<inventory_root>/system/chassis/motherboard/membuf1',
        'BOARD_6'    : '<inventory_root>/system/chassis/motherboard/membuf2',
        'BOARD_7'    : '<inventory_root>/system/chassis/motherboard/membuf3',
        'BOARD_8'    : '<inventory_root>/system/chassis/motherboard/membuf4',
        'BOARD_9'    : '<inventory_root>/system/chassis/motherboard/membuf5',
        'BOARD_10'   : '<inventory_root>/system/chassis/motherboard/membuf6',
        'BOARD_11'   : '<inventory_root>/system/chassis/motherboard/membuf7',
        'PRODUCT_12'   : '<inventory_root>/system/chassis/motherboard/dimm0',
        'PRODUCT_13'   : '<inventory_root>/system/chassis/motherboard/dimm1',
        'PRODUCT_14'   : '<inventory_root>/system/chassis/motherboard/dimm2',
        'PRODUCT_15'   : '<inventory_root>/system/chassis/motherboard/dimm3',
        'PRODUCT_16'   : '<inventory_root>/system/chassis/motherboard/dimm4',
        'PRODUCT_17'   : '<inventory_root>/system/chassis/motherboard/dimm5',
        'PRODUCT_18'   : '<inventory_root>/system/chassis/motherboard/dimm6',
        'PRODUCT_19'   : '<inventory_root>/system/chassis/motherboard/dimm7',
        'PRODUCT_20'   : '<inventory_root>/system/chassis/motherboard/dimm8',
        'PRODUCT_21'   : '<inventory_root>/system/chassis/motherboard/dimm9',
        'PRODUCT_22'   : '<inventory_root>/system/chassis/motherboard/dimm10',
        'PRODUCT_23'   : '<inventory_root>/system/chassis/motherboard/dimm11',
        'PRODUCT_24'   : '<inventory_root>/system/chassis/motherboard/dimm12',
        'PRODUCT_25'   : '<inventory_root>/system/chassis/motherboard/dimm13',
        'PRODUCT_26'   : '<inventory_root>/system/chassis/motherboard/dimm14',
        'PRODUCT_27'   : '<inventory_root>/system/chassis/motherboard/dimm15',
        'PRODUCT_28'   : '<inventory_root>/system/chassis/motherboard/dimm16',
        'PRODUCT_29'   : '<inventory_root>/system/chassis/motherboard/dimm17',
        'PRODUCT_30'   : '<inventory_root>/system/chassis/motherboard/dimm18',
        'PRODUCT_31'   : '<inventory_root>/system/chassis/motherboard/dimm19',
        'PRODUCT_32'   : '<inventory_root>/system/chassis/motherboard/dimm20',
        'PRODUCT_33'   : '<inventory_root>/system/chassis/motherboard/dimm21',
        'PRODUCT_34'   : '<inventory_root>/system/chassis/motherboard/dimm22',
        'PRODUCT_35'   : '<inventory_root>/system/chassis/motherboard/dimm23',
        'PRODUCT_36'   : '<inventory_root>/system/chassis/motherboard/dimm24',
        'PRODUCT_37'   : '<inventory_root>/system/chassis/motherboard/dimm25',
        'PRODUCT_38'   : '<inventory_root>/system/chassis/motherboard/dimm26',
        'PRODUCT_39'   : '<inventory_root>/system/chassis/motherboard/dimm27',
        'PRODUCT_40'   : '<inventory_root>/system/chassis/motherboard/dimm28',
        'PRODUCT_41'   : '<inventory_root>/system/chassis/motherboard/dimm29',
        'PRODUCT_42'   : '<inventory_root>/system/chassis/motherboard/dimm30',
        'PRODUCT_43'   : '<inventory_root>/system/chassis/motherboard/dimm31',
        'PRODUCT_47'   : '<inventory_root>/system/misc',
    },
    'SENSOR' : {
        0x04 : '/org/openbmc/sensors/host/HostStatus',
        0x05 : '/org/openbmc/sensors/host/BootProgress',
        0x08 : '/org/openbmc/sensors/host/cpu0/OccStatus',
        0x09 : '/org/openbmc/sensors/host/cpu1/OccStatus',
        0x0c : '<inventory_root>/system/chassis/motherboard/cpu0',
        0x0e : '<inventory_root>/system/chassis/motherboard/cpu1',
        0x1e : '<inventory_root>/system/chassis/motherboard/dimm3',
        0x1f : '<inventory_root>/system/chassis/motherboard/dimm2',
        0x20 : '<inventory_root>/system/chassis/motherboard/dimm1',
        0x21 : '<inventory_root>/system/chassis/motherboard/dimm0',
        0x22 : '<inventory_root>/system/chassis/motherboard/dimm7',
        0x23 : '<inventory_root>/system/chassis/motherboard/dimm6',
        0x24 : '<inventory_root>/system/chassis/motherboard/dimm5',
        0x25 : '<inventory_root>/system/chassis/motherboard/dimm4',
        0x26 : '<inventory_root>/system/chassis/motherboard/dimm11',
        0x27 : '<inventory_root>/system/chassis/motherboard/dimm10',
        0x28 : '<inventory_root>/system/chassis/motherboard/dimm9',
        0x29 : '<inventory_root>/system/chassis/motherboard/dimm8',
        0x2a : '<inventory_root>/system/chassis/motherboard/dimm15',
        0x2b : '<inventory_root>/system/chassis/motherboard/dimm14',
        0x2c : '<inventory_root>/system/chassis/motherboard/dimm13',
        0x2d : '<inventory_root>/system/chassis/motherboard/dimm12',
        0x2e : '<inventory_root>/system/chassis/motherboard/dimm19',
        0x2f : '<inventory_root>/system/chassis/motherboard/dimm18',
        0x30 : '<inventory_root>/system/chassis/motherboard/dimm17',
        0x31 : '<inventory_root>/system/chassis/motherboard/dimm16',
        0x32 : '<inventory_root>/system/chassis/motherboard/dimm23',
        0x33 : '<inventory_root>/system/chassis/motherboard/dimm22',
        0x34 : '<inventory_root>/system/chassis/motherboard/dimm21',
        0x35 : '<inventory_root>/system/chassis/motherboard/dimm20',
        0x36 : '<inventory_root>/system/chassis/motherboard/dimm27',
        0x37 : '<inventory_root>/system/chassis/motherboard/dimm26',
        0x38 : '<inventory_root>/system/chassis/motherboard/dimm25',
        0x39 : '<inventory_root>/system/chassis/motherboard/dimm24',
        0x3a : '<inventory_root>/system/chassis/motherboard/dimm31',
        0x3b : '<inventory_root>/system/chassis/motherboard/dimm30',
        0x3c : '<inventory_root>/system/chassis/motherboard/dimm29',
        0x3d : '<inventory_root>/system/chassis/motherboard/dimm28',
        0x3e : '<inventory_root>/system/chassis/motherboard/cpu0/core0',
        0x3f : '<inventory_root>/system/chassis/motherboard/cpu0/core1',
        0x40 : '<inventory_root>/system/chassis/motherboard/cpu0/core2',
        0x41 : '<inventory_root>/system/chassis/motherboard/cpu0/core3',
        0x42 : '<inventory_root>/system/chassis/motherboard/cpu0/core4',
        0x43 : '<inventory_root>/system/chassis/motherboard/cpu0/core5',
        0x44 : '<inventory_root>/system/chassis/motherboard/cpu0/core6',
        0x45 : '<inventory_root>/system/chassis/motherboard/cpu0/core7',
        0x46 : '<inventory_root>/system/chassis/motherboard/cpu0/core8',
        0x47 : '<inventory_root>/system/chassis/motherboard/cpu0/core9',
        0x48 : '<inventory_root>/system/chassis/motherboard/cpu0/core10',
        0x49 : '<inventory_root>/system/chassis/motherboard/cpu0/core11',
        0x4a : '<inventory_root>/system/chassis/motherboard/cpu1/core0',
        0x4b : '<inventory_root>/system/chassis/motherboard/cpu1/core1',
        0x4c : '<inventory_root>/system/chassis/motherboard/cpu1/core2',
        0x4d : '<inventory_root>/system/chassis/motherboard/cpu1/core3',
        0x4e : '<inventory_root>/system/chassis/motherboard/cpu1/core4',
        0x4f : '<inventory_root>/system/chassis/motherboard/cpu1/core5',
        0x50 : '<inventory_root>/system/chassis/motherboard/cpu1/core6',
        0x51 : '<inventory_root>/system/chassis/motherboard/cpu1/core7',
        0x52 : '<inventory_root>/system/chassis/motherboard/cpu1/core8',
        0x53 : '<inventory_root>/system/chassis/motherboard/cpu1/core9',
        0x54 : '<inventory_root>/system/chassis/motherboard/cpu1/core10',
        0x55 : '<inventory_root>/system/chassis/motherboard/cpu1/core11',
        0x56 : '<inventory_root>/system/chassis/motherboard/membuf0',
        0x57 : '<inventory_root>/system/chassis/motherboard/membuf1',
        0x58 : '<inventory_root>/system/chassis/motherboard/membuf2',
        0x59 : '<inventory_root>/system/chassis/motherboard/membuf3',
        0x5a : '<inventory_root>/system/chassis/motherboard/membuf4',
        0x5b : '<inventory_root>/system/chassis/motherboard/membuf5',
        0x5c : '<inventory_root>/system/chassis/motherboard/membuf6',
        0x5d : '<inventory_root>/system/chassis/motherboard/membuf7',
        0x5f : '/org/openbmc/sensors/host/BootCount',
        0x60 : '<inventory_root>/system/chassis/motherboard',
        0x61 : '<inventory_root>/system/systemevent',
        0x62 : '<inventory_root>/system/powerlimit',
        0x63 : '<inventory_root>/system/chassis/motherboard/refclock',
        0x64 : '<inventory_root>/system/chassis/motherboard/pcieclock',
        0xb1 : '<inventory_root>/system/chassis/motherboard/todclock',
        0xb2 : '<inventory_root>/system/chassis/motherboard/apss',
        0xb3 : '/org/openbmc/sensors/host/powercap',
        0xb5 : '/org/openbmc/sensors/host/OperatingSystemStatus',
        0xb6 : '<inventory_root>/system/chassis/motherboard/pcielink',
    },
    'GPIO_PRESENT' : {}
}

GPIO_CONFIG = {}
GPIO_CONFIG['BMC_POWER_UP'] = \
        {'gpio_pin': 'D1', 'direction': 'out'}
GPIO_CONFIG['SYS_PWROK_BUFF'] = \
        {'gpio_pin': 'D2', 'direction': 'in'}
GPIO_CONFIG['BMC_WD_CLEAR_PULSE_N'] = \
        {'gpio_pin': 'N4', 'direction': 'out'}
GPIO_CONFIG['CM1_OE_R_N'] = \
        {'gpio_pin': 'Q6', 'direction': 'out'}
GPIO_CONFIG['BMC_CP0_RESET_N'] = \
        {'gpio_pin': 'O2', 'direction': 'out'}
GPIO_CONFIG['BMC_CFAM_RESET_N_R'] = \
        {'gpio_pin': 'J2', 'direction': 'out'}
GPIO_CONFIG['PEX8718_DEVICES_RESET_N'] = \
        {'gpio_pin': 'B6', 'direction': 'out'}
GPIO_CONFIG['CP0_DEVICES_RESET_N'] = \
        {'gpio_pin': 'N3', 'direction': 'out'}
GPIO_CONFIG['CP1_DEVICES_RESET_N'] = \
        {'gpio_pin': 'N5', 'direction': 'out'}

GPIO_CONFIG['FSI_DATA'] = \
        {'gpio_pin': 'A5', 'direction': 'out'}
GPIO_CONFIG['FSI_CLK'] = \
        {'gpio_pin': 'A4', 'direction': 'out'}
GPIO_CONFIG['FSI_ENABLE'] = \
        {'gpio_pin': 'D0', 'direction': 'out'}
GPIO_CONFIG['CRONUS_SEL'] = \
        {'gpio_pin': 'A6', 'direction': 'out'}
GPIO_CONFIG['BMC_THROTTLE'] = \
        {'gpio_pin': 'J3', 'direction': 'out'}

GPIO_CONFIG['IDBTN']       = \
    { 'gpio_pin': 'Q7', 'direction': 'out' }
GPIO_CONFIG['POWER_BUTTON'] = \
        {'gpio_pin': 'E0', 'direction': 'both'}
GPIO_CONFIG['RESET_BUTTON'] = \
        {'gpio_pin': 'E4', 'direction': 'both'}

GPIO_CONFIG['PS0_PRES_N'] = \
        {'gpio_pin': 'P7', 'direction': 'in'}
GPIO_CONFIG['PS1_PRES_N'] = \
        {'gpio_pin': 'N0', 'direction': 'in'}
GPIO_CONFIG['CARD_PRES_N'] = \
        {'gpio_pin': 'J0', 'direction': 'in'}




def convertGpio(name):
    name = name.upper()
    c = name[0:1]
    offset = int(name[1:])
    a = ord(c)-65
    base = a*8+GPIO_BASE
    return base+offset


HWMON_CONFIG = {
    '4-0050' : {
        'names' : {
            'caps_curr_powercap' : { 'object_path' : 'powercap/curr_cap','poll_interval' : 10000,'scale' : 1,'units' : 'W' },
            'caps_curr_powerreading' : { 'object_path' : 'powercap/system_power','poll_interval' : 10000,'scale' : 1,'units' : 'W' },
            'caps_max_powercap' : { 'object_path' : 'powercap/max_cap','poll_interval' : 10000,'scale' : 1,'units' : 'W' },
            'caps_min_powercap' : { 'object_path' : 'powercap/min_cap','poll_interval' : 10000,'scale' : 1,'units' : 'W' },
            'caps_norm_powercap' : { 'object_path' : 'powercap/n_cap','poll_interval' : 10000,'scale' : 1,'units' : 'W' },
            'caps_user_powerlimit' : { 'object_path' : 'powercap/user_cap','poll_interval' : 10000,'scale' : 1,'units' : 'W' },
        },
        'labels' : {
        '176' :  { 'object_path' : 'temperature/cpu0/core0','poll_interval' : 5000,'scale' : 1000,'units' : 'C',
            'critical_upper' : 100, 'critical_lower' : -100, 'warning_upper' : 90, 'warning_lower' : -99, 'emergency_enabled' : True },
        '177' :  { 'object_path' : 'temperature/cpu0/core1','poll_interval' : 5000,'scale' : 1000,'units' : 'C',
            'critical_upper' : 100, 'critical_lower' : -100, 'warning_upper' : 90, 'warning_lower' : -99, 'emergency_enabled' : True },
        '178' :  { 'object_path' : 'temperature/cpu0/core2','poll_interval' : 5000,'scale' : 1000,'units' : 'C',
            'critical_upper' : 100, 'critical_lower' : -100, 'warning_upper' : 90, 'warning_lower' : -99, 'emergency_enabled' : True },
        '179' :  { 'object_path' : 'temperature/cpu0/core3','poll_interval' : 5000,'scale' : 1000,'units' : 'C',
            'critical_upper' : 100, 'critical_lower' : -100, 'warning_upper' : 90, 'warning_lower' : -99, 'emergency_enabled' : True },
        '180' :  { 'object_path' : 'temperature/cpu0/core4','poll_interval' : 5000,'scale' : 1000,'units' : 'C',
            'critical_upper' : 100, 'critical_lower' : -100, 'warning_upper' : 90, 'warning_lower' : -99, 'emergency_enabled' : True },
        '181' :  { 'object_path' : 'temperature/cpu0/core5','poll_interval' : 5000,'scale' : 1000,'units' : 'C',
            'critical_upper' : 100, 'critical_lower' : -100, 'warning_upper' : 90, 'warning_lower' : -99, 'emergency_enabled' : True },
        '182' :  { 'object_path' : 'temperature/cpu0/core6','poll_interval' : 5000,'scale' : 1000,'units' : 'C',
            'critical_upper' : 100, 'critical_lower' : -100, 'warning_upper' : 90, 'warning_lower' : -99, 'emergency_enabled' : True },
        '183' :  { 'object_path' : 'temperature/cpu0/core7','poll_interval' : 5000,'scale' : 1000,'units' : 'C',
            'critical_upper' : 100, 'critical_lower' : -100, 'warning_upper' : 90, 'warning_lower' : -99, 'emergency_enabled' : True },
        '184' :  { 'object_path' : 'temperature/cpu0/core8','poll_interval' : 5000,'scale' : 1000,'units' : 'C',
            'critical_upper' : 100, 'critical_lower' : -100, 'warning_upper' : 90, 'warning_lower' : -99, 'emergency_enabled' : True },
        '185' :  { 'object_path' : 'temperature/cpu0/core9','poll_interval' : 5000,'scale' : 1000,'units' : 'C',
            'critical_upper' : 100, 'critical_lower' : -100, 'warning_upper' : 90, 'warning_lower' : -99, 'emergency_enabled' : True },
        '186' :  { 'object_path' : 'temperature/cpu0/core10','poll_interval' : 5000,'scale' : 1000,'units' : 'C',
            'critical_upper' : 100, 'critical_lower' : -100, 'warning_upper' : 90, 'warning_lower' : -99, 'emergency_enabled' : True },
        '187' :  { 'object_path' : 'temperature/cpu0/core11','poll_interval' : 5000,'scale' : 1000,'units' : 'C',
            'critical_upper' : 100, 'critical_lower' : -100, 'warning_upper' : 90, 'warning_lower' : -99, 'emergency_enabled' : True },
        '102' :  { 'object_path' : 'temperature/dimm0','poll_interval' : 5000,'scale' : 1000,'units' : 'C' },
        '103' :  { 'object_path' : 'temperature/dimm1','poll_interval' : 5000,'scale' : 1000,'units' : 'C' },
        '104' :  { 'object_path' : 'temperature/dimm2','poll_interval' : 5000,'scale' : 1000,'units' : 'C' },
        '105' :  { 'object_path' : 'temperature/dimm3','poll_interval' : 5000,'scale' : 1000,'units' : 'C' },
        '106' :  { 'object_path' : 'temperature/dimm4','poll_interval' : 5000,'scale' : 1000,'units' : 'C' },
        '107' :  { 'object_path' : 'temperature/dimm5','poll_interval' : 5000,'scale' : 1000,'units' : 'C' },
        '108' :  { 'object_path' : 'temperature/dimm6','poll_interval' : 5000,'scale' : 1000,'units' : 'C' },
        '109' :  { 'object_path' : 'temperature/dimm7','poll_interval' : 5000,'scale' : 1000,'units' : 'C' },
        '110' :  { 'object_path' : 'temperature/dimm8','poll_interval' : 5000,'scale' : 1000,'units' : 'C' },
        '111' :  { 'object_path' : 'temperature/dimm9','poll_interval' : 5000,'scale' : 1000,'units' : 'C' },
        '112' :  { 'object_path' : 'temperature/dimm10','poll_interval' : 5000,'scale' : 1000,'units' : 'C' },
        '113' :  { 'object_path' : 'temperature/dimm11','poll_interval' : 5000,'scale' : 1000,'units' : 'C' },
        '114' :  { 'object_path' : 'temperature/dimm12','poll_interval' : 5000,'scale' : 1000,'units' : 'C' },
        '115' :  { 'object_path' : 'temperature/dimm13','poll_interval' : 5000,'scale' : 1000,'units' : 'C' },
        '116' :  { 'object_path' : 'temperature/dimm14','poll_interval' : 5000,'scale' : 1000,'units' : 'C' },
        '117' :  { 'object_path' : 'temperature/dimm15','poll_interval' : 5000,'scale' : 1000,'units' : 'C' },
        '94' :  { 'object_path' : 'temperature/membuf0','poll_interval' : 5000,'scale' : 1000,'units' : 'C' },
        '95' :  { 'object_path' : 'temperature/membuf1','poll_interval' : 5000,'scale' : 1000,'units' : 'C' },
        '96' :  { 'object_path' : 'temperature/membuf2','poll_interval' : 5000,'scale' : 1000,'units' : 'C' },
        '97' :  { 'object_path' : 'temperature/membuf3','poll_interval' : 5000,'scale' : 1000,'units' : 'C' },
        }
    },
    '5-0050' : {
        'labels' :  {
        '188' :  { 'object_path' : 'temperature/cpu1/core0','poll_interval' : 5000,'scale' : 1000,'units' : 'C',
            'critical_upper' : 100, 'critical_lower' : -100, 'warning_upper' : 90, 'warning_lower' : -99, 'emergency_enabled' : True },
        '189' :  { 'object_path' : 'temperature/cpu1/core1','poll_interval' : 5000,'scale' : 1000,'units' : 'C',
            'critical_upper' : 100, 'critical_lower' : -100, 'warning_upper' : 90, 'warning_lower' : -99, 'emergency_enabled' : True },
        '190' :  { 'object_path' : 'temperature/cpu1/core2','poll_interval' : 5000,'scale' : 1000,'units' : 'C',
            'critical_upper' : 100, 'critical_lower' : -100, 'warning_upper' : 90, 'warning_lower' : -99, 'emergency_enabled' : True },
        '191' :  { 'object_path' : 'temperature/cpu1/core3','poll_interval' : 5000,'scale' : 1000,'units' : 'C',
            'critical_upper' : 100, 'critical_lower' : -100, 'warning_upper' : 90, 'warning_lower' : -99, 'emergency_enabled' : True },
        '192' :  { 'object_path' : 'temperature/cpu1/core4','poll_interval' : 5000,'scale' : 1000,'units' : 'C',
            'critical_upper' : 100, 'critical_lower' : -100, 'warning_upper' : 90, 'warning_lower' : -99, 'emergency_enabled' : True },
        '193' :  { 'object_path' : 'temperature/cpu1/core5','poll_interval' : 5000,'scale' : 1000,'units' : 'C',
            'critical_upper' : 100, 'critical_lower' : -100, 'warning_upper' : 90, 'warning_lower' : -99, 'emergency_enabled' : True },
        '194' :  { 'object_path' : 'temperature/cpu1/core6','poll_interval' : 5000,'scale' : 1000,'units' : 'C',
            'critical_upper' : 100, 'critical_lower' : -100, 'warning_upper' : 90, 'warning_lower' : -99, 'emergency_enabled' : True },
        '195' :  { 'object_path' : 'temperature/cpu1/core7','poll_interval' : 5000,'scale' : 1000,'units' : 'C',
            'critical_upper' : 100, 'critical_lower' : -100, 'warning_upper' : 90, 'warning_lower' : -99, 'emergency_enabled' : True },
        '196' :  { 'object_path' : 'temperature/cpu1/core8','poll_interval' : 5000,'scale' : 1000,'units' : 'C',
            'critical_upper' : 100, 'critical_lower' : -100, 'warning_upper' : 90, 'warning_lower' : -99, 'emergency_enabled' : True },
        '197' :  { 'object_path' : 'temperature/cpu1/core9','poll_interval' : 5000,'scale' : 1000,'units' : 'C',
            'critical_upper' : 100, 'critical_lower' : -100, 'warning_upper' : 90, 'warning_lower' : -99, 'emergency_enabled' : True },
        '198' :  { 'object_path' : 'temperature/cpu1/core10','poll_interval' : 5000,'scale' : 1000,'units' : 'C',
            'critical_upper' : 100, 'critical_lower' : -100, 'warning_upper' : 90, 'warning_lower' : -99, 'emergency_enabled' : True },
        '199' :  { 'object_path' : 'temperature/cpu1/core11','poll_interval' : 5000,'scale' : 1000,'units' : 'C',
            'critical_upper' : 100, 'critical_lower' : -100, 'warning_upper' : 90, 'warning_lower' : -99, 'emergency_enabled' : True },
        '118' :  { 'object_path' : 'temperature/dimm16','poll_interval' : 5000,'scale' : 1000,'units' : 'C' },
        '119' :  { 'object_path' : 'temperature/dimm17','poll_interval' : 5000,'scale' : 1000,'units' : 'C' },
        '120' :  { 'object_path' : 'temperature/dimm18','poll_interval' : 5000,'scale' : 1000,'units' : 'C' },
        '121' :  { 'object_path' : 'temperature/dimm19','poll_interval' : 5000,'scale' : 1000,'units' : 'C' },
        '122' :  { 'object_path' : 'temperature/dimm20','poll_interval' : 5000,'scale' : 1000,'units' : 'C' },
        '123' :  { 'object_path' : 'temperature/dimm21','poll_interval' : 5000,'scale' : 1000,'units' : 'C' },
        '124' :  { 'object_path' : 'temperature/dimm22','poll_interval' : 5000,'scale' : 1000,'units' : 'C' },
        '125' :  { 'object_path' : 'temperature/dimm23','poll_interval' : 5000,'scale' : 1000,'units' : 'C' },
        '126' :  { 'object_path' : 'temperature/dimm24','poll_interval' : 5000,'scale' : 1000,'units' : 'C' },
        '127' :  { 'object_path' : 'temperature/dimm25','poll_interval' : 5000,'scale' : 1000,'units' : 'C' },
        '128' :  { 'object_path' : 'temperature/dimm26','poll_interval' : 5000,'scale' : 1000,'units' : 'C' },
        '129' :  { 'object_path' : 'temperature/dimm27','poll_interval' : 5000,'scale' : 1000,'units' : 'C' },
        '130' :  { 'object_path' : 'temperature/dimm28','poll_interval' : 5000,'scale' : 1000,'units' : 'C' },
        '131' :  { 'object_path' : 'temperature/dimm29','poll_interval' : 5000,'scale' : 1000,'units' : 'C' },
        '132' :  { 'object_path' : 'temperature/dimm30','poll_interval' : 5000,'scale' : 1000,'units' : 'C' },
        '133' :  { 'object_path' : 'temperature/dimm31','poll_interval' : 5000,'scale' : 1000,'units' : 'C' },
        '98' :  { 'object_path' : 'temperature/membuf4','poll_interval' : 5000,'scale' : 1000,'units' : 'C' },
        '99' :  { 'object_path' : 'temperature/membuf5','poll_interval' : 5000,'scale' : 1000,'units' : 'C' },
        '100' :  { 'object_path' : 'temperature/membuf6','poll_interval' : 5000,'scale' : 1000,'units' : 'C' },
        '101' :  { 'object_path' : 'temperature/membuf7','poll_interval' : 5000,'scale' : 1000,'units' : 'C' },
        }
    },
}

# Miscellaneous non-poll sensor with system specific properties.
# The sensor id is the same as those defined in ID_LOOKUP['SENSOR'].
MISC_SENSORS = {
	0x5f : { 'class' : 'BootCountSensor' },
	0x05 : { 'class' : 'BootProgressSensor' },
	0x08 : { 'class' : 'OccStatusSensor',
		'os_path' : '/sys/class/i2c-adapter/i2c-3/3-0050/online' },
	0x09 : { 'class' : 'OccStatusSensor',
		'os_path' : '/sys/class/i2c-adapter/i2c-3/3-0051/online' },
	0xb5 : { 'class' : 'OperatingSystemStatusSensor' },
	0xb3 : { 'class' : 'PowerCap',
		'os_path' : '/sys/class/hwmon/hwmon3/user_powercap' },
}
