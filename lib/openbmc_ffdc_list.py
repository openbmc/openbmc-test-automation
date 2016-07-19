#!/usr/bin/python
'''
#############################################################
#    @file     openbcm_ffdc_list.py
#    @author:  George Keishing
#
#    @brief    List for FFDC ( First failure data capture )
#              commands and files to be collected as a part
#              of the test case failure. 
#
#    Created on July 18, 2016
#    ----------------------------------------------------
#    @version  Contributor    Date       Description
#    ----------------------------------------------------
#      1.0     gkeishin     18/07/16     Initial create
#############################################################
'''

#-------------------
# FFDC default list
#-------------------

#-----------------------------------------------------------------
#Dict Name {  Index string : { Key String :  Comand string} }
#-----------------------------------------------------------------
FFDC_CMD = {
             'driver info' : 
                     { 
                        'FW Level' : 'cat /etc/os-release',
                        'OS Details' : 'uname -a',
                        'Build Info' : 'cat /etc/version',
                     },
             'BMC data' : 
                     { 
                        'System journal log' : 'journalctl --no-pager',
                        'Displays processor activity' : 'top -n 1 -b',
                     },
             'application data' : 
                     { 
                        'BMC state' : '/usr/sbin/obmcutil  state',
                     },
           }

# add file list needed to be offload from BMC
FFDC_FILE = {
             'BMC Files' : 
                     { 
                        #'Release info' : '/etc/os-release',
                     },
           }

#-----------------------------------------------------------------


# base class for FFDC default list
class openbcm_ffdc_list():

    ########################################################################
    #   @@brief   This method returns the list from the dictionary
    #   @param    i_type: @type string: string index lookup
    #   @return   List of key pair from the dictionary
    ########################################################################
    def get_ffdc_cmd(self,i_type):
        l_key_value_list=[]
        for key, value in FFDC_CMD[i_type].iteritems():
            temp = [key,value]
            l_key_value_list.append(temp)
        return l_key_value_list

    ########################################################################
    #   @@brief   This method returns the list from the dictionary
    #   @param    i_type: @type string: string index lookup
    #   @return   List of key pair from the dictionary
    ########################################################################
    def get_ffdc_file(self,i_type):
        l_key_value_list=[]
        for key, value in FFDC_FILE[i_type].iteritems():
            temp = [key,value]
            l_key_value_list.append(temp)
        return l_key_value_list

    ########################################################################
    #   @@brief   This method returns the list index from dictionary
    #   @return   List of index to the dictionary
    ########################################################################
    def get_ffdc_index(self):
        l_index_list=[]
        for index in FFDC_CMD:
            l_index_list.append(index)
        return l_index_list
