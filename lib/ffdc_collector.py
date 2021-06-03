#!/usr/bin/env python

r"""
See class prolog below for details.
"""

import os
import yaml
import time

from ssh_utility import SSHRemoteclient


class FFDCCollector:

    r"""
    Sends commands from configuration file to the targeted system to collect log files.
    Fetch and store generated files at the specified location.

    """

    def __init__(self, hostname, username, password, ffdc_config, location, protocol):

        r"""
        Description of argument(s):

        hostname                name/ip of the targeted (remote) system
        username                user on the targeted system with access to FFDC files
        password                password for user on targeted system
        ffdc_config             configuration file listing commands and files for FFDC
        location                Where to store collected FFDC
        protocol                protocol used to communicate with targeted system (ssh, REST, etc)

        """
        self.hostname = hostname
        self.username = username
        self.password = password
        self.ffdc_config = ffdc_config
        self.location = location
        self.protocol = protocol
        self.remote_client = None
        self.ffdc_dir_path = ""
        self.ffdc_prefix = ""
        self.receive_file_list = []
        self.target_type = ""

    def target_is_pingable(self):

        r"""
        Check if target system is ping-able.

        """
        response = os.system("ping -c 1 -w 2 " + self.hostname)
        if response == 0:
            return True
        else:
            return False

    def set_target_machine_type(self):
        r"""
        Determine and set target machine type.

        """
        # Default to openbmc for first few sprints
        self.target_type = "OPENBMC"

    def collect_ffdc(self):

        r"""
        Initiate FFDC Collection depending on requested protocol.

        """

        if not self.target_is_pingable():
            return False

        self.set_target_machine_type()

        if self.protocol == 'SSH':
            self.ssh_to_target_system()
            self.generate_ffdc_ssh()
        else:
            print("\nProtocol %s is not yet supported by this script.\n" % self.protocol)

    def ssh_to_target_system(self):
        r"""
        Open a ssh connection to targeted system.

        """

        self.remoteclient = SSHRemoteclient(self.hostname,
                                            self.username,
                                            self.password)

        self.remoteclient.ssh_remoteclient_login()

    def generate_ffdc_ssh(self):

        r"""
        Send commands in ffdc_config file via ssh to targeted system.

        """

        with open(self.ffdc_config, 'r') as file:
            ffdc_actions = yaml.load(file, Loader=yaml.FullLoader)

        for machine_type in ffdc_actions.keys():
            if machine_type == self.target_type:
                for item_type in ffdc_actions[machine_type].keys():
                    if item_type == "COMMANDS":
                        list_of_commands = ffdc_actions[machine_type][item_type]
                        for command in list_of_commands:
                            self.remoteclient.execute_command(command)

                # Get default values for scp action.
                # self.location == local system for now
                self.set_ffdc_defaults()
                for item_type in ffdc_actions[machine_type].keys():
                    if item_type == "FILES":
                        # Retrieving files from target system
                        list_of_files = ffdc_actions[machine_type][item_type]
                        self.scp_ffdc(self.ffdc_dir_path, self.ffdc_prefix, list_of_files)

    def scp_ffdc(self,
                 targ_dir_path,
                 targ_file_prefix="",
                 file_list=None,
                 quiet=None):

        r"""
        SCP all files in file_dict to the indicated directory on the local system.

        Description of argument(s):
        targ_dir_path                   The path of the directory to receive the files.
        targ_file_prefix                Prefix which will be pre-pended to each
                                        target file's name.
        file_dict                       A dictionary of files to scp from targeted system to this system

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

    def set_ffdc_defaults(self):

        r"""
        Set a default values for self.ffdc_dir_path and self.ffdc_prefix.

        Description of class variables:
        self.ffdc_dir_path  The dir path where collected ffdc data files should be put.

        self.ffdc_prefix    The prefix to be given to each ffdc file name.

        Collected ffdc file will be stored in dir /self.location/hostname_timestr/
        Individual ffdc file will have timestr_filename
        """

        timestr = time.strftime("%Y%m%d-%H%M%S")
        self.ffdc_dir_path = self.location + "/" + self.hostname + "_" + timestr + "/"
        self.ffdc_prefix = timestr + "_"

        if not os.path.exists(self.ffdc_dir_path):
            os.mkdir(self.ffdc_dir_path)

    def report(self):
        r"""
        Return list of files fetched from targeted system.
        """
        return self.receive_file_list
