# Romulus.py
#

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
        '/org/openbmc/control/flash/bios' : 0,
    },
}

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
    '<inventory_root>/system/chassis/motherboard/cpu0/core10' : { 'fru_type' : 'CORE', 'is_fru' : False, },
    '<inventory_root>/system/chassis/motherboard/cpu0/core11' : { 'fru_type' : 'CORE', 'is_fru' : False, },
    '<inventory_root>/system/chassis/motherboard/cpu0/core12' : { 'fru_type' : 'CORE', 'is_fru' : False, },
    '<inventory_root>/system/chassis/motherboard/cpu0/core13' : { 'fru_type' : 'CORE', 'is_fru' : False, },
    '<inventory_root>/system/chassis/motherboard/cpu0/core14' : { 'fru_type' : 'CORE', 'is_fru' : False, },
    '<inventory_root>/system/chassis/motherboard/cpu0/core15' : { 'fru_type' : 'CORE', 'is_fru' : False, },
    '<inventory_root>/system/chassis/motherboard/cpu0/core16' : { 'fru_type' : 'CORE', 'is_fru' : False, },
    '<inventory_root>/system/chassis/motherboard/cpu0/core17' : { 'fru_type' : 'CORE', 'is_fru' : False, },
    '<inventory_root>/system/chassis/motherboard/cpu0/core18' : { 'fru_type' : 'CORE', 'is_fru' : False, },
    '<inventory_root>/system/chassis/motherboard/cpu0/core19' : { 'fru_type' : 'CORE', 'is_fru' : False, },
    '<inventory_root>/system/chassis/motherboard/cpu0/core20' : { 'fru_type' : 'CORE', 'is_fru' : False, },
    '<inventory_root>/system/chassis/motherboard/cpu0/core21' : { 'fru_type' : 'CORE', 'is_fru' : False, },
    '<inventory_root>/system/chassis/motherboard/cpu0/core22' : { 'fru_type' : 'CORE', 'is_fru' : False, },
    '<inventory_root>/system/chassis/motherboard/cpu0/core23' : { 'fru_type' : 'CORE', 'is_fru' : False, },

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
    '<inventory_root>/system/chassis/motherboard/cpu1/core12' : { 'fru_type' : 'CORE', 'is_fru' : False, },
    '<inventory_root>/system/chassis/motherboard/cpu1/core13' : { 'fru_type' : 'CORE', 'is_fru' : False, },
    '<inventory_root>/system/chassis/motherboard/cpu1/core14' : { 'fru_type' : 'CORE', 'is_fru' : False, },
    '<inventory_root>/system/chassis/motherboard/cpu1/core15' : { 'fru_type' : 'CORE', 'is_fru' : False, },
    '<inventory_root>/system/chassis/motherboard/cpu1/core16' : { 'fru_type' : 'CORE', 'is_fru' : False, },
    '<inventory_root>/system/chassis/motherboard/cpu1/core17' : { 'fru_type' : 'CORE', 'is_fru' : False, },
    '<inventory_root>/system/chassis/motherboard/cpu1/core18' : { 'fru_type' : 'CORE', 'is_fru' : False, },
    '<inventory_root>/system/chassis/motherboard/cpu1/core19' : { 'fru_type' : 'CORE', 'is_fru' : False, },
    '<inventory_root>/system/chassis/motherboard/cpu1/core20' : { 'fru_type' : 'CORE', 'is_fru' : False, },
    '<inventory_root>/system/chassis/motherboard/cpu1/core21' : { 'fru_type' : 'CORE', 'is_fru' : False, },
    '<inventory_root>/system/chassis/motherboard/cpu1/core22' : { 'fru_type' : 'CORE', 'is_fru' : False, },
    '<inventory_root>/system/chassis/motherboard/cpu1/core23' : { 'fru_type' : 'CORE', 'is_fru' : False, },

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
}

ID_LOOKUP = {
    'FRU' : {
        0x01 : '<inventory_root>/system/chassis/motherboard/cpu0',
        0x02 : '<inventory_root>/system/chassis/motherboard/cpu1',
        0x03 : '<inventory_root>/system/chassis/motherboard',
        0x04 : '<inventory_root>/system/chassis/motherboard/dimm0',
        0x05 : '<inventory_root>/system/chassis/motherboard/dimm1',
        0x06 : '<inventory_root>/system/chassis/motherboard/dimm2',
        0x07 : '<inventory_root>/system/chassis/motherboard/dimm3',
        0x08 : '<inventory_root>/system/chassis/motherboard/dimm4',
        0x09 : '<inventory_root>/system/chassis/motherboard/dimm5',
        0x0a : '<inventory_root>/system/chassis/motherboard/dimm6',
        0x0b : '<inventory_root>/system/chassis/motherboard/dimm7',
        0x0c : '<inventory_root>/system/chassis/motherboard/dimm8',
        0x0d : '<inventory_root>/system/chassis/motherboard/dimm9',
        0x0e : '<inventory_root>/system/chassis/motherboard/dimm10',
        0x0f : '<inventory_root>/system/chassis/motherboard/dimm11',
        0x10 : '<inventory_root>/system/chassis/motherboard/dimm12',
        0x11 : '<inventory_root>/system/chassis/motherboard/dimm13',
        0x12 : '<inventory_root>/system/chassis/motherboard/dimm14',
        0x13 : '<inventory_root>/system/chassis/motherboard/dimm15',
    },
    'FRU_STR' : {
        'PRODUCT_0'  : '<inventory_root>/system/bios',
        'BOARD_1'    : '<inventory_root>/system/chassis/motherboard/cpu0',
        'BOARD_2'    : '<inventory_root>/system/chassis/motherboard/cpu1',
        'CHASSIS_3'  : '<inventory_root>/system/chassis/motherboard',
        'BOARD_3'    : '<inventory_root>/system/misc',
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
        'PRODUCT_47'   : '<inventory_root>/system/misc',
    },
    'SENSOR' : {
        0x01 : '/org/openbmc/sensors/host/HostStatus',
        0x02 : '/org/openbmc/sensors/host/BootProgress',
        0x03 : '/org/openbmc/sensors/host/cpu0/OccStatus',
        0x04 : '/org/openbmc/sensors/host/cpu1/OccStatus',
        0x08 : '<inventory_root>/system/chassis/motherboard/cpu0',
        0x09 : '<inventory_root>/system/chassis/motherboard/cpu1',
        0x0b : '<inventory_root>/system/chassis/motherboard/dimm0',
        0x0c : '<inventory_root>/system/chassis/motherboard/dimm1',
        0x0d : '<inventory_root>/system/chassis/motherboard/dimm2',
        0x0e : '<inventory_root>/system/chassis/motherboard/dimm3',
        0x0f : '<inventory_root>/system/chassis/motherboard/dimm4',
        0x10 : '<inventory_root>/system/chassis/motherboard/dimm5',
        0x11 : '<inventory_root>/system/chassis/motherboard/dimm6',
        0x12 : '<inventory_root>/system/chassis/motherboard/dimm7',
        0x13 : '<inventory_root>/system/chassis/motherboard/dimm8',
        0x14 : '<inventory_root>/system/chassis/motherboard/dimm9',
        0x15 : '<inventory_root>/system/chassis/motherboard/dimm10',
        0x16 : '<inventory_root>/system/chassis/motherboard/dimm11',
        0x17 : '<inventory_root>/system/chassis/motherboard/dimm12',
        0x18 : '<inventory_root>/system/chassis/motherboard/dimm13',
        0x19 : '<inventory_root>/system/chassis/motherboard/dimm14',
        0x1a : '<inventory_root>/system/chassis/motherboard/dimm15',
        0x2b : '<inventory_root>/system/chassis/motherboard/cpu0/core0',
        0x2c : '<inventory_root>/system/chassis/motherboard/cpu0/core1',
        0x2d : '<inventory_root>/system/chassis/motherboard/cpu0/core2',
        0x2e : '<inventory_root>/system/chassis/motherboard/cpu0/core3',
        0x2f : '<inventory_root>/system/chassis/motherboard/cpu0/core4',
        0x30 : '<inventory_root>/system/chassis/motherboard/cpu0/core5',
        0x31 : '<inventory_root>/system/chassis/motherboard/cpu0/core6',
        0x32 : '<inventory_root>/system/chassis/motherboard/cpu0/core7',
        0x33 : '<inventory_root>/system/chassis/motherboard/cpu0/core8',
        0x34 : '<inventory_root>/system/chassis/motherboard/cpu0/core9',
        0x35 : '<inventory_root>/system/chassis/motherboard/cpu0/core10',
        0x36 : '<inventory_root>/system/chassis/motherboard/cpu0/core11',
        0x37 : '<inventory_root>/system/chassis/motherboard/cpu0/core12',
        0x38 : '<inventory_root>/system/chassis/motherboard/cpu0/core13',
        0x39 : '<inventory_root>/system/chassis/motherboard/cpu0/core14',
        0x3a : '<inventory_root>/system/chassis/motherboard/cpu0/core15',
        0x3b : '<inventory_root>/system/chassis/motherboard/cpu0/core16',
        0x3c : '<inventory_root>/system/chassis/motherboard/cpu0/core17',
        0x3d : '<inventory_root>/system/chassis/motherboard/cpu0/core18',
        0x3e : '<inventory_root>/system/chassis/motherboard/cpu0/core19',
        0x3f : '<inventory_root>/system/chassis/motherboard/cpu0/core20',
        0x40 : '<inventory_root>/system/chassis/motherboard/cpu0/core21',
        0x41 : '<inventory_root>/system/chassis/motherboard/cpu0/core22',
        0x42 : '<inventory_root>/system/chassis/motherboard/cpu0/core23',
        0x43 : '<inventory_root>/system/chassis/motherboard/cpu1/core0',
        0x44 : '<inventory_root>/system/chassis/motherboard/cpu1/core1',
        0x45 : '<inventory_root>/system/chassis/motherboard/cpu1/core2',
        0x46 : '<inventory_root>/system/chassis/motherboard/cpu1/core3',
        0x47 : '<inventory_root>/system/chassis/motherboard/cpu1/core4',
        0x48 : '<inventory_root>/system/chassis/motherboard/cpu1/core5',
        0x49 : '<inventory_root>/system/chassis/motherboard/cpu1/core6',
        0x4a : '<inventory_root>/system/chassis/motherboard/cpu1/core7',
        0x4b : '<inventory_root>/system/chassis/motherboard/cpu1/core8',
        0x4c : '<inventory_root>/system/chassis/motherboard/cpu1/core9',
        0x4d : '<inventory_root>/system/chassis/motherboard/cpu1/core10',
        0x4e : '<inventory_root>/system/chassis/motherboard/cpu1/core11',
        0x4f : '<inventory_root>/system/chassis/motherboard/cpu1/core12',
        0x50 : '<inventory_root>/system/chassis/motherboard/cpu1/core13',
        0x51 : '<inventory_root>/system/chassis/motherboard/cpu1/core14',
        0x52 : '<inventory_root>/system/chassis/motherboard/cpu1/core15',
        0x53 : '<inventory_root>/system/chassis/motherboard/cpu1/core16',
        0x54 : '<inventory_root>/system/chassis/motherboard/cpu1/core17',
        0x55 : '<inventory_root>/system/chassis/motherboard/cpu1/core18',
        0x56 : '<inventory_root>/system/chassis/motherboard/cpu1/core19',
        0x57 : '<inventory_root>/system/chassis/motherboard/cpu1/core20',
        0x58 : '<inventory_root>/system/chassis/motherboard/cpu1/core21',
        0x59 : '<inventory_root>/system/chassis/motherboard/cpu1/core22',
        0x5a : '<inventory_root>/system/chassis/motherboard/cpu1/core23',
        0x8b : '/org/openbmc/sensors/host/BootCount',
        0x8c : '<inventory_root>/system/chassis/motherboard',
        0x8d : '<inventory_root>/system/chassis/motherboard/refclock',
        0x8e : '<inventory_root>/system/chassis/motherboard/pcieclock',
        0x8f : '<inventory_root>/system/chassis/motherboard/todclock',
        0x90 : '<inventory_root>/system/systemevent',
        0x91 : '/org/openbmc/sensors/host/OperatingSystemStatus',
        0x92 : '<inventory_root>/system/chassis/motherboard/pcielink',
#        0x08 : '<inventory_root>/system/powerlimit',
#        0x10 : '<inventory_root>/system/chassis/motherboard/apss',
#        0x06 : '/org/openbmc/sensors/host/powercap',
    },
    'GPIO_PRESENT' : {}
}

GPIO_CONFIG = {}
GPIO_CONFIG['SOFTWARE_PGOOD'] = \
        {'gpio_pin': 'R1', 'direction': 'out'}
GPIO_CONFIG['BMC_POWER_UP'] = \
        {'gpio_pin': 'D1', 'direction': 'out'}
GPIO_CONFIG['SYS_PWROK_BUFF'] = \
        {'gpio_pin': 'D2', 'direction': 'in'}
GPIO_CONFIG['BMC_WD_CLEAR_PULSE_N'] = \
        {'gpio_pin': 'N5', 'direction': 'out'}
GPIO_CONFIG['CHECKSTOP'] = \
        {'gpio_pin': 'J2', 'direction': 'falling'}
GPIO_CONFIG['BMC_CP0_RESET_N'] = \
        {'gpio_pin': 'A1', 'direction': 'out'}
GPIO_CONFIG['BMC_CP0_PERST_ENABLE_R'] = \
        {'gpio_pin': 'A3', 'direction': 'out'}
GPIO_CONFIG['FSI_DATA'] = \
        {'gpio_pin': 'AA2', 'direction': 'out'}
GPIO_CONFIG['FSI_CLK'] = \
        {'gpio_pin': 'AA0', 'direction': 'out'}
GPIO_CONFIG['FSI_ENABLE'] = \
        {'gpio_pin': 'D0', 'direction': 'out'}

# DBG_CP0_MUX_SEL
GPIO_CONFIG['CRONUS_SEL'] = \
        {'gpio_pin': 'A6', 'direction': 'out'}
GPIO_CONFIG['BMC_THROTTLE'] = \
        {'gpio_pin': 'J3', 'direction': 'out'}
GPIO_CONFIG['IDBTN']       = \
        {'gpio_pin': 'Q7', 'direction': 'out'}

# PM_FP_PWRBTN_IN_L
GPIO_CONFIG['POWER_BUTTON'] = \
        {'gpio_pin': 'I3', 'direction': 'both'}

# PM_NMIBTN_IN_L
GPIO_CONFIG['RESET_BUTTON'] = \
        {'gpio_pin': 'J1', 'direction': 'both'}

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
        '176' :  { 'object_path' : 'temperature/cpu0/core0','poll_interval' : 5000,'scale' : -3,'units' : 'C',
            'critical_upper' : 100, 'critical_lower' : -100, 'warning_upper' : 90, 'warning_lower' : -99, 'emergency_enabled' : True },
        '177' :  { 'object_path' : 'temperature/cpu0/core1','poll_interval' : 5000,'scale' : -3,'units' : 'C',
            'critical_upper' : 100, 'critical_lower' : -100, 'warning_upper' : 90, 'warning_lower' : -99, 'emergency_enabled' : True },
        '178' :  { 'object_path' : 'temperature/cpu0/core2','poll_interval' : 5000,'scale' : -3,'units' : 'C',
            'critical_upper' : 100, 'critical_lower' : -100, 'warning_upper' : 90, 'warning_lower' : -99, 'emergency_enabled' : True },
        '179' :  { 'object_path' : 'temperature/cpu0/core3','poll_interval' : 5000,'scale' : -3,'units' : 'C',
            'critical_upper' : 100, 'critical_lower' : -100, 'warning_upper' : 90, 'warning_lower' : -99, 'emergency_enabled' : True },
        '180' :  { 'object_path' : 'temperature/cpu0/core4','poll_interval' : 5000,'scale' : -3,'units' : 'C',
            'critical_upper' : 100, 'critical_lower' : -100, 'warning_upper' : 90, 'warning_lower' : -99, 'emergency_enabled' : True },
        '181' :  { 'object_path' : 'temperature/cpu0/core5','poll_interval' : 5000,'scale' : -3,'units' : 'C',
            'critical_upper' : 100, 'critical_lower' : -100, 'warning_upper' : 90, 'warning_lower' : -99, 'emergency_enabled' : True },
        '182' :  { 'object_path' : 'temperature/cpu0/core6','poll_interval' : 5000,'scale' : -3,'units' : 'C',
            'critical_upper' : 100, 'critical_lower' : -100, 'warning_upper' : 90, 'warning_lower' : -99, 'emergency_enabled' : True },
        '183' :  { 'object_path' : 'temperature/cpu0/core7','poll_interval' : 5000,'scale' : -3,'units' : 'C',
            'critical_upper' : 100, 'critical_lower' : -100, 'warning_upper' : 90, 'warning_lower' : -99, 'emergency_enabled' : True },
        '184' :  { 'object_path' : 'temperature/cpu0/core8','poll_interval' : 5000,'scale' : -3,'units' : 'C',
            'critical_upper' : 100, 'critical_lower' : -100, 'warning_upper' : 90, 'warning_lower' : -99, 'emergency_enabled' : True },
        '185' :  { 'object_path' : 'temperature/cpu0/core9','poll_interval' : 5000,'scale' : -3,'units' : 'C',
            'critical_upper' : 100, 'critical_lower' : -100, 'warning_upper' : 90, 'warning_lower' : -99, 'emergency_enabled' : True },
        '186' :  { 'object_path' : 'temperature/cpu0/core10','poll_interval' : 5000,'scale' : -3,'units' : 'C',
            'critical_upper' : 100, 'critical_lower' : -100, 'warning_upper' : 90, 'warning_lower' : -99, 'emergency_enabled' : True },
        '187' :  { 'object_path' : 'temperature/cpu0/core11','poll_interval' : 5000,'scale' : -3,'units' : 'C',
            'critical_upper' : 100, 'critical_lower' : -100, 'warning_upper' : 90, 'warning_lower' : -99, 'emergency_enabled' : True },
        '102' :  { 'object_path' : 'temperature/dimm0','poll_interval' : 5000,'scale' : -3,'units' : 'C' },
        '103' :  { 'object_path' : 'temperature/dimm1','poll_interval' : 5000,'scale' : -3,'units' : 'C' },
        '104' :  { 'object_path' : 'temperature/dimm2','poll_interval' : 5000,'scale' : -3,'units' : 'C' },
        '105' :  { 'object_path' : 'temperature/dimm3','poll_interval' : 5000,'scale' : -3,'units' : 'C' },
        '106' :  { 'object_path' : 'temperature/dimm4','poll_interval' : 5000,'scale' : -3,'units' : 'C' },
        '107' :  { 'object_path' : 'temperature/dimm5','poll_interval' : 5000,'scale' : -3,'units' : 'C' },
        '108' :  { 'object_path' : 'temperature/dimm6','poll_interval' : 5000,'scale' : -3,'units' : 'C' },
        '109' :  { 'object_path' : 'temperature/dimm7','poll_interval' : 5000,'scale' : -3,'units' : 'C' },
        }
    },
    '5-0050' : {
        'labels' :  {
        '188' :  { 'object_path' : 'temperature/cpu1/core0','poll_interval' : 5000,'scale' : -3,'units' : 'C',
            'critical_upper' : 100, 'critical_lower' : -100, 'warning_upper' : 90, 'warning_lower' : -99, 'emergency_enabled' : True },
        '189' :  { 'object_path' : 'temperature/cpu1/core1','poll_interval' : 5000,'scale' : -3,'units' : 'C',
            'critical_upper' : 100, 'critical_lower' : -100, 'warning_upper' : 90, 'warning_lower' : -99, 'emergency_enabled' : True },
        '190' :  { 'object_path' : 'temperature/cpu1/core2','poll_interval' : 5000,'scale' : -3,'units' : 'C',
            'critical_upper' : 100, 'critical_lower' : -100, 'warning_upper' : 90, 'warning_lower' : -99, 'emergency_enabled' : True },
        '191' :  { 'object_path' : 'temperature/cpu1/core3','poll_interval' : 5000,'scale' : -3,'units' : 'C',
            'critical_upper' : 100, 'critical_lower' : -100, 'warning_upper' : 90, 'warning_lower' : -99, 'emergency_enabled' : True },
        '192' :  { 'object_path' : 'temperature/cpu1/core4','poll_interval' : 5000,'scale' : -3,'units' : 'C',
            'critical_upper' : 100, 'critical_lower' : -100, 'warning_upper' : 90, 'warning_lower' : -99, 'emergency_enabled' : True },
        '193' :  { 'object_path' : 'temperature/cpu1/core5','poll_interval' : 5000,'scale' : -3,'units' : 'C',
            'critical_upper' : 100, 'critical_lower' : -100, 'warning_upper' : 90, 'warning_lower' : -99, 'emergency_enabled' : True },
        '194' :  { 'object_path' : 'temperature/cpu1/core6','poll_interval' : 5000,'scale' : -3,'units' : 'C',
            'critical_upper' : 100, 'critical_lower' : -100, 'warning_upper' : 90, 'warning_lower' : -99, 'emergency_enabled' : True },
        '195' :  { 'object_path' : 'temperature/cpu1/core7','poll_interval' : 5000,'scale' : -3,'units' : 'C',
            'critical_upper' : 100, 'critical_lower' : -100, 'warning_upper' : 90, 'warning_lower' : -99, 'emergency_enabled' : True },
        '196' :  { 'object_path' : 'temperature/cpu1/core8','poll_interval' : 5000,'scale' : -3,'units' : 'C',
            'critical_upper' : 100, 'critical_lower' : -100, 'warning_upper' : 90, 'warning_lower' : -99, 'emergency_enabled' : True },
        '197' :  { 'object_path' : 'temperature/cpu1/core9','poll_interval' : 5000,'scale' : -3,'units' : 'C',
            'critical_upper' : 100, 'critical_lower' : -100, 'warning_upper' : 90, 'warning_lower' : -99, 'emergency_enabled' : True },
        '198' :  { 'object_path' : 'temperature/cpu1/core10','poll_interval' : 5000,'scale' : -3,'units' : 'C',
            'critical_upper' : 100, 'critical_lower' : -100, 'warning_upper' : 90, 'warning_lower' : -99, 'emergency_enabled' : True },
        '199' :  { 'object_path' : 'temperature/cpu1/core11','poll_interval' : 5000,'scale' : -3,'units' : 'C',
            'critical_upper' : 100, 'critical_lower' : -100, 'warning_upper' : 90, 'warning_lower' : -99, 'emergency_enabled' : True },
        '110' :  { 'object_path' : 'temperature/dimm8','poll_interval' : 5000,'scale' : -3,'units' : 'C' },
        '111' :  { 'object_path' : 'temperature/dimm9','poll_interval' : 5000,'scale' : -3,'units' : 'C' },
        '112' :  { 'object_path' : 'temperature/dimm10','poll_interval' : 5000,'scale' : -3,'units' : 'C' },
        '113' :  { 'object_path' : 'temperature/dimm11','poll_interval' : 5000,'scale' : -3,'units' : 'C' },
        '114' :  { 'object_path' : 'temperature/dimm12','poll_interval' : 5000,'scale' : -3,'units' : 'C' },
        '115' :  { 'object_path' : 'temperature/dimm13','poll_interval' : 5000,'scale' : -3,'units' : 'C' },
        '116' :  { 'object_path' : 'temperature/dimm14','poll_interval' : 5000,'scale' : -3,'units' : 'C' },
        '117' :  { 'object_path' : 'temperature/dimm15','poll_interval' : 5000,'scale' : -3,'units' : 'C' },
        }
    },
}


GPIO_CONFIGS = {
    'power_config' : {
        'power_good_in' : 'SYS_PWROK_BUFF',
        'power_up_outs' : [
            ('SOFTWARE_PGOOD', True),
            ('BMC_POWER_UP', True),
        ],
        'reset_outs' : [
            ('BMC_CP0_RESET_N', False),
            ('BMC_CP0_PERST_ENABLE_R', False),
        ],
    },
    'hostctl_config' : {
        'fsi_data' : 'FSI_DATA',
        'fsi_clk' : 'FSI_CLK',
        'fsi_enable' : 'FSI_ENABLE',
        'cronus_sel' : 'CRONUS_SEL',
        'optionals' : [
        ],
    },
}


# Miscellaneous non-poll sensor with system specific properties.
# The sensor id is the same as those defined in ID_LOOKUP['SENSOR'].
MISC_SENSORS = {
    0x8b : { 'class' : 'BootCountSensor' },
    0x02 : { 'class' : 'BootProgressSensor' },
    #OCC active sensors aren't in the P9 XML yet.  These are wrong.
    0x03 : { 'class' : 'OccStatusSensor',
        'os_path' : '/sys/bus/i2c/devices/3-0050/online' },
    0x04 : { 'class' : 'OccStatusSensor',
        'os_path' : '/sys/bus/i2c/devices/3-0051/online' },
    0x91 : { 'class' : 'OperatingSystemStatusSensor' },
    #0x06 : { 'class' : 'PowerCap',
    #    'os_path' : '/sys/class/hwmon/hwmon3/user_powercap' },
}

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
