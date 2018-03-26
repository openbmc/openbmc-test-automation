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
        'BMC Uptime': 'uptime',
        'BMC File System Disk Space Usage': 'df -hT',
        'BMC Date Time': 'date;/sbin/hwclock --show;/usr/bin/timedatectl'
    },
    'APPLICATION DATA':
    {
        'BMC state': '/usr/sbin/obmcutil state',
    },
}
# Add file name and correcponding command needed for BMC
FFDC_BMC_FILE = {
    'BMC FILES':
    {
        # File Name         Command
        'BMC_proc_list': 'top -n 1 -b',
        'BMC_proc_fd_active_list': 'ls -Al /proc/*/fd/',
        'BMC_journalctl_nopager': 'journalctl --no-pager',
        'BMC_journalctl_pretty': 'journalctl -o json-pretty',
        'BMC_dmesg': 'dmesg',
        'BMC_procinfo': 'cat /proc/cpuinfo',
        'BMC_meminfo': 'cat /proc/meminfo',
        'BMC_systemd': 'systemctl status --all',
    },
}
# Add file name and correcponding command needed for all Linux distributions
FFDC_OS_ALL_DISTROS_FILE = {
    'OS FILES':
    {
        # File Name         Command
        'OS_msglog': 'cat /sys/firmware/opal/msglog',
        'OS_cpufrequency': 'ppc64_cpu --frequency',
        'OS_dmesg': 'dmesg',
        'OS_boot': 'cat /var/log/boot.log',
        'OS_procinfo': 'cat /proc/cpuinfo',
        'OS_meminfo': 'cat /proc/meminfo',
        'OS_netstat': 'netstat -a',
        'OS_lspci': 'lspci',
        'OS_lscpu': 'lscpu',
        'OS_lscfg': 'lscfg',
    },
}
# Add file name and correcponding command needed for Ubuntu Linux
FFDC_OS_UBUNTU_FILE = {
    'OS FILES':
    {
        # File Name         Command
        'OS_isusb': 'lsusb -t ; lsusb -v',
        'OS_kern': 'tail -n 50000 /var/log/kern.log',
        'OS_authlog': 'cat /var/log/auth.log; cat /var/log/auth.log.1',
        'OS_syslog': 'tail -n 200000 /var/log/syslog',
        'OS_info': 'uname -a; dpkg -s opal-prd; dpkg -s ipmitool',
    },
}
# Add file name and correcponding command needed for RHEL Linux
FFDC_OS_RHEL_FILE = {
    'OS FILES':
    {
        # File Name         Command
        'OS_rsct': '/usr/bin/ctversion -bv',
        'OS_secure': 'cat /var/log/secure',
        'OS_syslog': 'tail -n 200000 /var/log/messages',
        'OS_info': 'lsb_release -a; cat /etc/redhat-release; uname -a; rpm -qa',
    },
}
# Add file name and correcponding command needed for RHEL Linux
FFDC_OS_IBM_POWERKVM_FILE = {
    'OS FILES':
    {
        # File Name         Command
        'OS_secure': 'cat /var/log/secure',
        'OS_syslog': 'tail -n 200000 /var/log/messages',
        'OS_info': 'lsb_release -a; uname -a; rpm -qa',
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
ENUMERATE_OCC = OPENPOWER_BASE + 'control/enumerate'
ENUMERATE_DUMPS = OPENBMC_BASE + 'dumps/enumerate'

# Add file name and correcponding Get Request
FFDC_GET_REQUEST = {
    'GET REQUESTS':
    {
        # File Name         Command
        'FIRMWARE_list': ENUMERATE_SW,
        'BMC_sensor_list': ENUMERATE_SENSORS,
        'BMC_control_list': ENUMERATE_CONTROL,
        'BMC_inventory': ENUMERATE_INVENTORY,
        'BMC_elog': ENUMERATE_ELOG,
        'BMC_led': ENUMERATE_LED,
        'BMC_state': ENUMERATE_STATE,
        'OCC_state': ENUMERATE_OCC,
        'BMC_dumps': ENUMERATE_DUMPS,
    },
}
# Define your keywords in method/utils and call here
FFDC_METHOD_CALL = {
    'BMC LOGS':
    {
        # Description             Keyword name
        'FFDC Generic Report': 'BMC FFDC Manifest',
        'BMC Specific Files': 'BMC FFDC Files',
        'Get Request FFDC': 'BMC FFDC Get Requests',
        'OS FFDC': 'OS FFDC Files',
        'Core Files': 'SCP Coredump Files',
        'SEL Log': 'Collect eSEL Log',
        'Sys Inventory Files': 'System Inventory Files',
        'Dump Log': 'Collect Dump Log',
        'Dump Files': 'SCP Dump Files'
    },
}
# -----------------------------------------------------------------
# base class for FFDC default list


class openbmc_ffdc_list():
    def get_ffdc_bmc_cmd(self, i_type):
        r"""
        ########################################################################
        #   @brief    This method returns the list from the dictionary for cmds
        #   @param    i_type: @type string: string index lookup
        #   @return   List of key pair from the dictionary
        ########################################################################
        """
        return FFDC_BMC_CMD[i_type].items()

    def get_ffdc_bmc_file(self, i_type):
        r"""
        ########################################################################
        #   @brief    This method returns the list from the dictionary for scp
        #   @param    i_type: @type string: string index lookup
        #   @return   List of key pair from the dictionary
        ########################################################################
        """
        return FFDC_BMC_FILE[i_type].items()

    def get_ffdc_get_request(self, i_type):
        r"""
        ########################################################################
        #   @brief    This method returns the list from the dictionary for scp
        #   @param    i_type: @type string: string index lookup
        #   @return   List of key pair from the dictionary
        ########################################################################
        """
        return FFDC_GET_REQUEST[i_type].items()

    def get_ffdc_cmd_index(self):
        r"""
        ########################################################################
        #   @brief    This method returns the list index from dictionary
        #   @return   List of index to the dictionary
        ########################################################################
        """
        return FFDC_BMC_CMD.keys()

    def get_ffdc_get_request_index(self):
        r"""
        ########################################################################
        #   @brief    This method returns the list index from dictionary
        #   @return   List of index to the dictionary
        ########################################################################
        """
        return FFDC_GET_REQUEST.keys()

    def get_ffdc_file_index(self):
        r"""
        ########################################################################
        #   @brief    This method returns the list index from dictionary
        #   @return   List of index to the dictionary
        ########################################################################
        """
        return FFDC_BMC_FILE.keys()

    def get_ffdc_method_index(self):
        r"""
        ########################################################################
        #   @brief    This method returns the key pair from the dictionary
        #   @return   Index of the method dictionary
        ########################################################################
        """
        return FFDC_METHOD_CALL.keys()

    def get_ffdc_method_desc(self,
                             index):
        r"""
        ########################################################################
        #   @brief   This method returns the just the keys from the dictionary.
        #   @return  List of ffdc descriptions.
        ########################################################################
        """
        return FFDC_METHOD_CALL[index].keys()

    def get_ffdc_method_call(self, i_type):
        r"""
        ########################################################################
        #   @brief    This method returns the key pair from the dictionary
        #   @return   List of key pair keywords
        ########################################################################
        """
        return FFDC_METHOD_CALL[i_type].items()

    def get_ffdc_os_all_distros_index(self):
        r"""
        ########################################################################
        #   @brief    This method returns the key pair from the dictionary
        #   @return   Index of the method dictionary
        ########################################################################
        """
        return FFDC_OS_ALL_DISTROS_FILE.keys()

    def get_ffdc_os_all_distros_call(self, i_type):
        r"""
        ########################################################################
        #   @brief    This method returns the key pair from the dictionary
        #   @return   List of key pair keywords
        ########################################################################
        """
        return FFDC_OS_ALL_DISTROS_FILE[i_type].items()

    def get_ffdc_os_distro_index(self, distro):
        r"""
        ########################################################################
        #   @brief    This method returns the key pair from the dictionary
        #   @return   Index of the method dictionary
        ########################################################################
        """
        distro_file = "FFDC_OS_" + str(distro).upper() + "_FILE"
        return eval(distro_file).keys()

    def get_ffdc_os_distro_call(self, i_type, distro):
        r"""
        ########################################################################
        #   @brief    This method returns the key pair from the dictionary
        #   @return   List of key pair keywords
        ########################################################################
        """
        distro_file = "FFDC_OS_" + str(distro).upper() + "_FILE"
        return eval(distro_file)[i_type].items()

    def get_strip_string(self, i_str):
        r"""
        ########################################################################
        #   @brief    Returns the stripped strings
        #   @param    i_str: @type string: string name
        #   @return   Remove all special chars and return the string
        ########################################################################
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
