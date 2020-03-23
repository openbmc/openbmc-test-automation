#!/usr/bin/python
r"""
#    @file     openbmc_ffdc_list.py
#    @brief    List for FFDC ( First failure data capture )
#              commands and files to be collected as a part
#              of the test case failure.
"""
# -------------------
# FFDC default list
# -------------------
# -----------------------------------------------------------------
# Dict Name {  Index string : { Key String :  Command string} }
# -----------------------------------------------------------------
# Add cmd's needed to be part of the ffdc report manifest file
FFDC_BMC_CMD = {
    'DRIVER INFO':
    {
        # String Name         Command
        'FW Level': 'cat /etc/os-release',
        'FW Timestamp': 'cat /etc/timestamp',
    },
    'BMC DATA':
    {
        'BMC OS': 'uname -a',
        'BMC Uptime': 'uptime;cat /proc/uptime',
        'BMC File System Disk Space Usage': 'df -hT',
        'BMC Date Time': 'date;/sbin/hwclock --show;/usr/bin/timedatectl'
    },
    'APPLICATION DATA':
    {
        'BMC state': '/usr/bin/obmcutil state',
    },
}
# Add file name and correcponding command needed for BMC
FFDC_BMC_FILE = {
    'BMC FILES':
    {
        # File Name         Command
        'BMC_flash_side.txt': 'cat /sys/class/watchdog/watchdog1/bootstatus >/tmp/BMC_flash_side.txt 2>&1',
        'BMC_proc_list.txt': 'top -n 1 -b >/tmp/BMC_proc_list.txt 2>&1',
        'BMC_proc_fd_active_list.txt': 'ls -Al /proc/*/fd/ >/tmp/BMC_proc_fd_active_list.txt 2>&1',
        'BMC_journalctl_nopager.txt': 'journalctl --no-pager >/tmp/BMC_journalctl_nopager.txt 2>&1',
        'BMC_journalctl_pretty.json': 'journalctl -o json-pretty >/tmp/BMC_journalctl_pretty.json 2>&1',
        'BMC_dmesg.txt': 'dmesg >/tmp/BMC_dmesg.txt 2>&1',
        'BMC_procinfo.txt': 'cat /proc/cpuinfo >/tmp/BMC_procinfo.txt 2>&1',
        'BMC_meminfo.txt': 'cat /proc/meminfo >/tmp/BMC_meminfo.txt 2>&1',
        'BMC_systemd.txt': 'systemctl status --all >/tmp/BMC_systemd.txt 2>&1',
        'BMC_obmc_console.txt': 'cat /var/log/obmc-console.log >/tmp/BMC_obmc_console.txt 2>&1',
        'PEL_logs_list.json': 'peltool -l >/tmp/PEL_logs_list.json 2>&1',
        'PEL_logs_display.json': 'peltool -a >/tmp/PEL_logs_display.json 2>&1',
    },
}
# Add file name and corresponding command needed for all Linux distributions
FFDC_OS_ALL_DISTROS_FILE = {
    'OS FILES':
    {
        # File Name         Command
        'OS_msglog.txt': 'cat /sys/firmware/opal/msglog >/tmp/OS_msglog.txt 2>&1',
        'OS_cpufrequency.txt': 'ppc64_cpu --frequency '
        + '>/tmp/OS_cpufrequency.txt 2>&1',
        'OS_dmesg.txt': 'dmesg >/tmp/OS_dmesg.txt 2>&1',
        'OS_opal_prd.txt': 'cat /var/log/opal-prd* >/tmp/OS_opal_prd.txt 2>&1',
        'OS_boot.txt': 'cat /var/log/boot.log >/tmp/OS_boot.txt 2>&1',
        'OS_procinfo.txt': 'cat /proc/cpuinfo >/tmp/OS_procinfo.txt 2>&1',
        'OS_meminfo.txt': 'cat /proc/meminfo >/tmp/OS_meminfo.txt 2>&1',
        'OS_netstat.txt': 'netstat -a >/tmp/OS_netstat.txt 2>&1',
        'OS_lspci.txt': 'lspci >/tmp/OS_lspci.txt 2>&1',
        'OS_lscpu.txt': 'lscpu >/tmp/OS_lscpu.txt 2>&1',
        'OS_lscfg.txt': 'lscfg >/tmp/OS_lscfg.txt 2>&1',
        'OS_journalctl_nopager.txt': 'journalctl --no-pager -b '
        + '> /tmp/OS_journalctl_nopager.txt  2>&1',
    },
}
# Add file name and correcponding command needed for Ubuntu Linux
FFDC_OS_UBUNTU_FILE = {
    'OS FILES':
    {
        # File Name         Command
        'OS_isusb.txt': '{ lsusb -t ; lsusb -v ; } >/tmp/OS_isub.txt 2>&1',
        'OS_kern.txt': 'tail -n 50000 /var/log/kern.log >/tmp/OS_kern.txt 2>&1',
        'OS_authlog.txt': '{ cat /var/log/auth.log; cat /var/log/auth.log.1 ; } '
        + '>/tmp/OS_authlog.txt 2>&1',
        'OS_syslog.txt': 'tail -n 200000 /var/log/syslog >/tmp/OS_syslog.txt 2>&1',
        'OS_info.txt': '{ uname -a; dpkg -s opal-prd; dpkg -s ipmitool ; } '
        + '>/tmp/OS_info.txt 2>&1',
        'OS_sosreport.txt': '{ rm -rf /tmp/sosreport*FFDC* ; sosreport --batch --tmp-dir '
        + '/tmp --ticket-number FFDC ; } >/tmp/OS_sosreport.txt 2>&1',
    },
}
# Add file name and correcponding command needed for RHEL Linux
FFDC_OS_RHEL_FILE = {
    'OS FILES':
    {
        # File Name         Command
        'OS_rsct.txt': '/usr/bin/ctversion -bv >/tmp/OS_rsct.txt 2>&1',
        'OS_secure.txt': 'cat /var/log/secure >/tmp/OS_secure.txt 2>&1',
        'OS_syslog.txt': 'tail -n 200000 /var/log/messages '
        + '>/tmp/OS_syslog.txt 2>&1',
        'OS_info.txt': '{ lsb_release -a; cat /etc/redhat-release; '
        + 'uname -a; rpm -qa ; } >/tmp/OS_info.txt 2>&1',
        'OS_sosreport.txt': '{ rm -rf /tmp/sosreport*FFDC* ; sosreport --batch --tmp-dir '
        + '/tmp --label FFDC ; } >/tmp/OS_sosreport.txt 2>&1',
    },
}

OPENBMC_BASE = '/xyz/openbmc_project/'
OPENPOWER_BASE = '/org/open_power/'
ENUMERATE_SENSORS = OPENBMC_BASE + 'sensors/enumerate'
ENUMERATE_INVENTORY = OPENBMC_BASE + 'inventory/enumerate'
ENUMERATE_ELOG = OPENBMC_BASE + 'logging/entry/enumerate'
ENUMERATE_LED = OPENBMC_BASE + 'led/enumerate'
ENUMERATE_SW = OPENBMC_BASE + 'software/enumerate'
ENUMERATE_CONTROL = OPENBMC_BASE + 'control/enumerate'
ENUMERATE_STATE = OPENBMC_BASE + 'state/enumerate'
ENUMERATE_OCC = OPENPOWER_BASE + '/enumerate'
ENUMERATE_DUMPS = OPENBMC_BASE + 'dumps/enumerate'
ENUMERATE_USER = OPENBMC_BASE + 'user/enumerate'

# Add file name and correcponding Get Request
FFDC_GET_REQUEST = {
    'GET REQUESTS':
    {
        # File Name         Command
        'FIRMWARE_list.txt': ENUMERATE_SW,
        'BMC_sensor_list.txt': ENUMERATE_SENSORS,
        'BMC_control_list.txt': ENUMERATE_CONTROL,
        'BMC_inventory.txt': ENUMERATE_INVENTORY,
        'BMC_elog.txt': ENUMERATE_ELOG,
        'BMC_led.txt': ENUMERATE_LED,
        'BMC_state.txt': ENUMERATE_STATE,
        'OCC_state.txt': ENUMERATE_OCC,
        'BMC_dumps.txt': ENUMERATE_DUMPS,
        'BMC_USER.txt': ENUMERATE_USER,
    },
}
# Define your keywords in method/utils and call here
FFDC_METHOD_CALL = {
    'BMC LOGS':
    {
        # Description               Keyword name
        'FFDC Generic Report': 'BMC FFDC Manifest',
        'BMC Specific Files': 'BMC FFDC Files',
        'Get Request FFDC': 'BMC FFDC Get Requests',
        'OS FFDC': 'OS FFDC Files',
        'Core Files': 'SCP Coredump Files',
        'SEL Log': 'Collect eSEL Log',
        'Sys Inventory Files': 'System Inventory Files',
        'Dump Log': 'Collect Dump Log',
        'Dump Files': 'SCP Dump Files',
        'PEL Files': 'Collect PEL Log',
        'Redfish Log': 'Enumerate Redfish Resources',
    },
}
# -----------------------------------------------------------------
# base class for FFDC default list


class openbmc_ffdc_list():
    def get_ffdc_bmc_cmd(self, i_type):
        r"""
        #######################################################################
        #   @brief    This method returns the list from the dictionary for cmds
        #   @param    i_type: @type string: string index lookup
        #   @return   List of key pair from the dictionary
        #######################################################################
        """
        return FFDC_BMC_CMD[i_type].items()

    def get_ffdc_bmc_file(self, i_type):
        r"""
        #######################################################################
        #   @brief    This method returns the list from the dictionary for scp
        #   @param    i_type: @type string: string index lookup
        #   @return   List of key pair from the dictionary
        #######################################################################
        """
        return FFDC_BMC_FILE[i_type].items()

    def get_ffdc_get_request(self, i_type):
        r"""
        #######################################################################
        #   @brief    This method returns the list from the dictionary for scp
        #   @param    i_type: @type string: string index lookup
        #   @return   List of key pair from the dictionary
        #######################################################################
        """
        return FFDC_GET_REQUEST[i_type].items()

    def get_ffdc_cmd_index(self):
        r"""
        #######################################################################
        #   @brief    This method returns the list index from dictionary
        #   @return   List of index to the dictionary
        #######################################################################
        """
        return FFDC_BMC_CMD.keys()

    def get_ffdc_get_request_index(self):
        r"""
        #######################################################################
        #   @brief    This method returns the list index from dictionary
        #   @return   List of index to the dictionary
        #######################################################################
        """
        return FFDC_GET_REQUEST.keys()

    def get_ffdc_file_index(self):
        r"""
        #######################################################################
        #   @brief    This method returns the list index from dictionary
        #   @return   List of index to the dictionary
        #######################################################################
        """
        return FFDC_BMC_FILE.keys()

    def get_ffdc_method_index(self):
        r"""
        #######################################################################
        #   @brief    This method returns the key pair from the dictionary
        #   @return   Index of the method dictionary
        #######################################################################
        """
        return FFDC_METHOD_CALL.keys()

    def get_ffdc_method_desc(self,
                             index):
        r"""
        #######################################################################
        #   @brief   This method returns the just the keys from the dictionary.
        #   @return  List of ffdc descriptions.
        #######################################################################
        """
        return FFDC_METHOD_CALL[index].keys()

    def get_ffdc_method_call(self, i_type):
        r"""
        #######################################################################
        #   @brief    This method returns the key pair from the dictionary
        #   @return   List of key pair keywords
        #######################################################################
        """
        return FFDC_METHOD_CALL[i_type].items()

    def get_ffdc_os_all_distros_index(self):
        r"""
        #######################################################################
        #   @brief    This method returns the key pair from the dictionary
        #   @return   Index of the method dictionary
        #######################################################################
        """
        return FFDC_OS_ALL_DISTROS_FILE.keys()

    def get_ffdc_os_all_distros_call(self, i_type):
        r"""
        #######################################################################
        #   @brief    This method returns the key pair from the dictionary
        #   @return   List of key pair keywords
        #######################################################################
        """
        return FFDC_OS_ALL_DISTROS_FILE[i_type].items()

    def get_ffdc_os_distro_index(self, distro):
        r"""
        #######################################################################
        #   @brief    This method returns the key pair from the dictionary
        #   @return   Index of the method dictionary
        #######################################################################
        """
        distro_file = "FFDC_OS_" + str(distro).upper() + "_FILE"
        return eval(distro_file).keys()

    def get_ffdc_os_distro_call(self, i_type, distro):
        r"""
        #######################################################################
        #   @brief    This method returns the key pair from the dictionary
        #   @return   List of key pair keywords
        #######################################################################
        """
        distro_file = "FFDC_OS_" + str(distro).upper() + "_FILE"
        return eval(distro_file)[i_type].items()

    def get_strip_string(self, i_str):
        r"""
        #######################################################################
        #   @brief    Returns the stripped strings
        #   @param    i_str: @type string: string name
        #   @return   Remove all special chars and return the string
        #######################################################################
        """
        return ''.join(e for e in i_str if e.isalnum())

    def get_esel_index(self, esel_list):
        r"""
        #######################################################################
        #   @brief    Returns the eSEL binary index.
        #   @param    esel_ist: @type list: eSEL list.
        #   @return   Index of "ESEL=" in the list.
        #######################################################################
        """
        index = [i for i, str in enumerate(esel_list) if 'ESEL=' in str]
        return index[0]

    def get_dump_index(self, dump_list):
        r"""
        #######################################################################
        #   @brief    Returns the eSEL binary index.
        #   @param    esel_ist: @type list: eSEL list.
        #   @return   Index of "ESEL=" in the list.
        #######################################################################
        """
        index = [i for i, str in enumerate(dump_list) if 'DUMP=' in str]
        return index[0]
