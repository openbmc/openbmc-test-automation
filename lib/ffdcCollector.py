#!/usr/bin/env python
 
r"""
See class prolog below for details.
"""

import os
import sys
import yaml
import time

from ssh_suite import ssh_remoteclient

class ffdcCollector:

    r"""
    Entry Point for FFDC Collector agent.
 
    This class send commands from configuration file to the input target system
    then store generated files at the requested location 
    
    """

    def __init__(self, hostname, username, password, ffdc_config, location, protocol):
        self.hostname = hostname
        self.username = username
        self.password = password
        self.ffdc_config = ffdc_config
        self.location = location
        self.protocol = protocol
        self.remoteclient = None
        self.ffdc_dir_path = ""
        self.ffdc_prefix = ""
        self.receive_file_list = []
        self.targetType = ""
        
    def hostIsPingable(self):

        r"""
        Check if target system is ping-able  

        """
        response = os.system("ping -c 1 -w 2 " + self.hostname)
        if response == 0:
            return True
        else:
            return False

    def setTargetMachineType(self):
        r"""
        Determine and set target machine type.

        """
        # Default to openbmc for first few sprints
        self.targetType = "OPENBMC"

    def doCollectFFDC(self):

        r"""
        Initiate FFDC Collection depending on requested protocol 

        """
        
        if not self.hostIsPingable():
            return False

        self.setTargetMachineType()
        
        if self.protocol == 'SSH':
            self.sshToRemoteHost()
            self.generateFFDC_ssh()
        else:
            print("\nProtocol %s is not yet supported by this script.\n" % self.protocol)

    def sshToRemoteHost(self):
        r"""
        open a ssh connection to remote host
        """
        
        self.remoteclient = ssh_remoteclient(self.hostname,
                                            self.username,
                                            self.password) 
        self.remoteclient.ssh_remoteclient_login()
        
    def generateFFDC_ssh(self):

        r"""
        Send command in ffdc_config file via ssh for to target system to generate FFDC data 

        """

        with open(self.ffdc_config, 'r') as file:
            ffdc_actions = yaml.load(file,  Loader=yaml.FullLoader)        
        
        for machineType in ffdc_actions.keys():
            if machineType == self.targetType:
                for itemType in ffdc_actions[machineType].keys():
                    if itemType == "COMMANDS":
                        list_of_commands = ffdc_actions[machineType][itemType]
                        for command in list_of_commands:
                            self.remoteclient.execute_command(command)
                    
                # Get default values for arguments.
                # self.location == local system for now
                self.set_ffdc_defaults(self.ffdc_dir_path, self.ffdc_prefix)
                for itemType in ffdc_actions[machineType].keys():
                    if itemType == "FILES":
                        # Retrieving files from remote host
                        list_of_files = ffdc_actions[machineType][itemType]
                        self.scp_ffdc(self.ffdc_dir_path, self.ffdc_prefix, list_of_files)
                
    def scp_ffdc(self, targ_dir_path,
              targ_file_prefix="",
              file_list=None,
              quiet=None):
        r"""
        SCP all files in file_dict to the indicated directory on the local system
        and set a list of the new files in global receive_file_list.

        Description of argument(s):
        targ_dir_path                   The path of the directory to receive the files.
        targ_file_prefix                Prefix which will be pre-pended to each
                                        target file's name.
        file_dict                       A dictionary of files to scp from target host to this system

        """

        self.remoteclient.scp_connection()
        
        self.receive_file_list = []
        for filename in file_list:
            source_file_path = filename
            targ_file_path = targ_dir_path + targ_file_prefix + filename.split('/')[-1]
            
            # self.remoteclient.scp_file_from_remote() returns means the scp was 
            # completed without exception.
            self.remoteclient.scp_file_from_remote(source_file_path, targ_file_path)
            self.receive_file_list.append(targ_file_path)

            if not quiet:
                print(source_file_path + " was fetched from " + self.hostname + "\n")
                
        self.remoteclient.ssh_remoteclient_disconnect()


    def set_ffdc_defaults(self,ffdc_dir_path=None,
                      ffdc_prefix=None):
        r"""
        Set a default values for self.ffdc_dir_path and self.ffdc_prefix 

        Description of arguments:
        ffdc_dir_path  The dir path where FFDC data should be put.
        
        ffdc_prefix    The prefix to be given to each FFDC file name generated.

        Collected ffdc file will be stored in dir /self.location/hostname_timestr/
        Individual ffdc file will have timestr_filename
        """
    
        timestr = time.strftime("%Y%m%d-%H%M%S")
        self.ffdc_dir_path = self.location + "/" + self.hostname + "_" +  timestr + "/"
        self.ffdc_prefix = timestr + "_"
        
        if not os.path.exists(self.ffdc_dir_path):
            os.mkdir(self.ffdc_dir_path)
                
    def report(self):
        r"""
        Return list of files fetched from remote host 
        """
        return self.receive_file_list
            
        
