#!/usr/bin/python
r"""
#############################################################
#    @file     openbmc_ffdc_list.py
#
#    @brief    List for FFDC ( First failure data capture )
#              commands and files to be collected as a part
#              of the test case failure.
#############################################################
"""

# -------------------
# FFDC default list
# -------------------

# -----------------------------------------------------------------
# Dict Name {  Index string : { Key String :  Comand string} }
# -----------------------------------------------------------------
# Add cmd's needed to be part of the ffdc report manifest file
FFDC_BMC_CMD = {
    'DRIVER INFO':
    {
        # String Name         Command
        'Build Info': 'cat /etc/version',
        'FW Level': 'cat /etc/os-release',
    },
    'BMC DATA':
    {
        'BMC OS': 'uname -a',
        'BMC Uptime': 'uptime',
        'BMC Proc Info': 'cat /proc/cpuinfo',
        'BMC Mem Info': 'cat /proc/meminfo',
        'BMC File System Disk Space Usage': 'df -hT',
    },
    'APPLICATION DATA':
    {
        'BMC state': '/usr/sbin/obmcutil  state',
    },
}

# Add file name and correcponding command needed for BMC
FFDC_BMC_FILE = {
    'BMC FILES':
    {
        # File Name         Command
        'BMC_proc_list': 'top -n 1 -b',
        'BMC_journalctl.log': 'journalctl --no-pager',
        'BMC_dmesg': 'dmesg',
    },
}

# Add file name and correcponding Get Request
FFDC_GET_REQUEST = {
    'GET REQUESTS':
    {
        # File Name         Command
        'BMC_sensor_list': '/org/openbmc/sensors/enumerate',
        'BMC_inventory': '/org/openbmc/inventory/system/enumerate',
        'BMC_led': '/org/openbmc/control/led/enumerate',
        'BMC_record_log': '/org/openbmc/records/events/enumerate',
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

    def get_ffdc_method_call(self, i_type):
        r"""
        ########################################################################
        #   @brief    This method returns the key pair from the dictionary
        #   @return   List of key pair keywords
        ########################################################################
        """
        return FFDC_METHOD_CALL[i_type].items()

    def get_strip_string(self, i_str):
        r"""
        ########################################################################
        #   @brief    Returns the stripped strings
        #   @param    i_str: @type string: string name
        #   @return   Remove all special chars and return the string
        ########################################################################
        """
        return ''.join(e for e in i_str if e.isalnum())
