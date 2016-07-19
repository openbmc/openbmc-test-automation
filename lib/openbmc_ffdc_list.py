#!/usr/bin/python
'''
#############################################################
#    @file     openbmc_ffdc_list.py
#    @author:  George Keishing
#
#    @brief    List for FFDC ( First failure data capture )
#              commands and files to be collected as a part
#              of the test case failure.
#############################################################
'''

#-------------------
# FFDC default list
#-------------------

#-----------------------------------------------------------------
#Dict Name {  Index string : { Key String :  Comand string} }
#-----------------------------------------------------------------
FFDC_CMD = {
             'DRIVER INFO' :
                     {
                        'FW Level' : 'cat /etc/os-release',
                        'OS Details' : 'uname -a',
                        'Build Info' : 'cat /etc/version',
                     },
             'BMC DATA' :
                     {
                        'System journal log' : 'journalctl --no-pager',
                        'Displays processor activity' : 'top -n 1 -b',
                     },
             'APPLICATION DATA' :
                     {
                        'BMC state' : '/usr/sbin/obmcutil  state',
                     },
           }

# add file list needed to be offload from BMC
FFDC_FILE = {
             'BMC FILES' :
                     {
                        # Sample example how to add the file that
                        # is needed to be offloaded
                        #'Release info' : '/etc/os-release',
                     },
           }

#-----------------------------------------------------------------


# base class for FFDC default list
class openbmc_ffdc_list():

    ########################################################################
    #   @@brief   This method returns the list from the dictionary for cmds
    #   @param    i_type: @type string: string index lookup
    #   @return   List of key pair from the dictionary
    ########################################################################
    def get_ffdc_cmd(self,i_type):
        return FFDC_CMD[i_type].items()

    ########################################################################
    #   @@brief   This method returns the list from the dictionary for scp
    #   @param    i_type: @type string: string index lookup
    #   @return   List of key pair from the dictionary
    ########################################################################
    def get_ffdc_file(self,i_type):
        return FFDC_FILE[i_type].items()

    ########################################################################
    #   @@brief   This method returns the list index from dictionary
    #   @return   List of index to the dictionary
    ########################################################################
    def get_ffdc_index(self):
        return FFDC_CMD.keys()
