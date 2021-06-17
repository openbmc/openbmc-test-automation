#!/usr/bin/env python

r"""
See class prolog below for details.
"""

import os
import sys
import yaml
import time
import platform
from errno import EACCES, EPERM
from ssh_utility import SSHRemoteclient


class FFDCCollector:

    r"""
    Sends commands from configuration file to the targeted system to collect log files.
    Fetch and store generated files at the specified location.

    """

    def __init__(self, hostname, username, password, ffdc_config, location):

        r"""
        Description of argument(s):

        hostname                name/ip of the targeted (remote) system
        username                user on the targeted system with access to FFDC files
        password                password for user on targeted system
        ffdc_config             configuration file listing commands and files for FFDC
        location                Where to store collected FFDC

        """
        if self.verify_script_env():
            self.hostname = hostname
            self.username = username
            self.password = password
            self.ffdc_config = ffdc_config
            self.location = location
            self.remote_client = None
            self.ffdc_dir_path = ""
            self.ffdc_prefix = ""
            self.receive_file_list = []
            self.target_type = ""
        else:
            sys.exit(-1)

    def verify_script_env(self):

        # Import to log version
        import click
        import paramiko

        run_env_ok = True
        print("\n\t---- Script host environment ----")
        print("\t{:<10}  {:<10}".format('Script hostname', os.uname()[1]))
        print("\t{:<10}  {:<10}".format('Script host os', platform.platform()))
        print("\t{:<10}  {:>10}".format('Python', platform.python_version()))
        print("\t{:<10}  {:>10}".format('PyYAML', yaml.__version__))
        print("\t{:<10}  {:>10}".format('click', click.__version__))
        print("\t{:<10}  {:>10}".format('paramiko', paramiko.__version__))

        if eval(yaml.__version__.replace('.', ',')) < (5, 4, 1):
            print("\n\tERROR: Python or python packages do not meet minimum version requirement.")
            print("\tERROR: PyYAML version 5.4.1 or higher is needed.\n")
            run_env_ok = False

        print("\t---- End script host environment ----")
        return run_env_ok

    def target_is_pingable(self):

        r"""
        Check if target system is ping-able.

        """
        response = os.system("ping -c 1 -w 2 %s  2>&1 >/dev/null" % self.hostname)
        if response == 0:
            print("\n\t%s is ping-able.\t\t\t [OK]" % self.hostname)
            return True
        else:
            print("\n>>>>>\tERROR: %s is not ping-able. FFDC collection aborted.\n" % self.hostname)
            sys.exit(-1)

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

        print("\n\n\t---- Start communicating with %s ----" % self.hostname)
        if self.target_is_pingable():
            # Check supported protocol ping,ssh, redfish are working.
            self.ssh_to_target_system()
            # Verify top level directory exists for storage
            self.validate_local_store(self.location)
            self.set_target_machine_type()
            self.generate_ffdc()

    def ssh_to_target_system(self):
        r"""
        Open a ssh connection to targeted system.

        """

        self.remoteclient = SSHRemoteclient(self.hostname,
                                            self.username,
                                            self.password)

        self.remoteclient.ssh_remoteclient_login()
        print("\n\t%s SSH connection established.\t [OK]" % self.hostname)


    def generate_ffdc(self):

        r"""
        Send commands in ffdc_config file to targeted system.

        """

        with open(self.ffdc_config, 'r') as file:
            ffdc_actions = yaml.load(file, Loader=yaml.FullLoader)

        for machine_type in ffdc_actions.keys():
            if machine_type == self.target_type:

                if (ffdc_actions[machine_type]['PROTOCOL'][0] == 'SSH'):

                    print("\n\t---- Collecting FFDC on " + self.hostname + " ----")
                    list_of_commands = ffdc_actions[machine_type]['COMMANDS']
                    progress_counter = 0
                    for command in list_of_commands:
                        self.remoteclient.execute_command(command)
                        progress_counter += 1
                        self.print_progress(progress_counter)

                    print("\n\n\tCopying FFDC from remote system %s \n\n" % self.hostname)
                    # Get default values for scp action.
                    # self.location == local system for now
                    self.set_ffdc_defaults()
                    # Retrieving files from target system
                    list_of_files = ffdc_actions[machine_type]['FILES']
                    self.scp_ffdc(self.ffdc_dir_path, self.ffdc_prefix, list_of_files)
                else:
                    print("\n\tProtocol %s is not yet supported by this script.\n"
                          % ffdc_actions[machine_type]['PROTOCOL'][0])

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
        progress_counter = 0
        for filename in file_list:
            source_file_path = filename
            targ_file_path = targ_dir_path + targ_file_prefix + filename.split('/')[-1]

            # self.remoteclient.scp_file_from_remote() completed without exception,
            # add file to the receiving file list.
            scp_result = self.remoteclient.scp_file_from_remote(source_file_path, targ_file_path)
            if scp_result:
                self.receive_file_list.append(targ_file_path)

            if not quiet:
                if scp_result:
                    print("\t\tSuccessfully copied from " + self.hostname + ':' + source_file_path + ".\n")
                else:
                    print("\t\tFail to copy from " + self.hostname + ':' + source_file_path + ".\n")
            else:
                progress_counter += 1
                self.print_progress(progress_counter)

        self.remoteclient.ssh_remoteclient_disconnect()

    def set_ffdc_defaults(self):

        r"""
        Set a default value for self.ffdc_dir_path and self.ffdc_prefix.
        Collected ffdc file will be stored in dir /self.location/hostname_timestr/.
        Individual ffdc file will have timestr_filename.

        Description of class variables:
        self.ffdc_dir_path  The dir path where collected ffdc data files should be put.

        self.ffdc_prefix    The prefix to be given to each ffdc file name.

        """

        timestr = time.strftime("%Y%m%d-%H%M%S")
        self.ffdc_dir_path = self.location + "/" + self.hostname + "_" + timestr + "/"
        self.ffdc_prefix = timestr + "_"
        self.validate_local_store(self.ffdc_dir_path)

    def validate_local_store(self, dir_path):
        r"""
        Ensure path exists to store FFDC files locally.

        Description of variable:
        dir_path  The dir path where collected ffdc data files will be stored.

        """

        if not os.path.exists(dir_path):
            try:
                os.mkdir(dir_path, 0o755)
            except (IOError, OSError) as e:
                # PermissionError
                if e.errno == EPERM or e.errno == EACCES:
                    print('>>>>>\tERROR: os.mkdir %s failed with PermissionError.\n' % dir_path)
                else:
                    print('>>>>>\tERROR: os.mkdir %s failed with %s.\n' % (dir_path, e.strerror))
                sys.exit(-1)

    def print_progress(self, progress):
        r"""
        Print activity progress +

        Description of variable:
        progress  Progress counter.

        """

        sys.stdout.write("\r\t" + "+" * progress)
        sys.stdout.flush()
        time.sleep(.1)
