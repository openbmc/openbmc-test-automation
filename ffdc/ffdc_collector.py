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
import subprocess
from ssh_utility import SSHRemoteclient
from tn_utility import TelnetRemoteclient


class FFDCCollector:

    r"""
    Sends commands from configuration file to the targeted system to collect log files.
    Fetch and store generated files at the specified location.

    """

    # List of supported OSes.
    supported_oses = ['OPENBMC', 'RHEL', 'AIX', 'UBUNTU', 'FSP']

    def __init__(self,
                 hostname,
                 username,
                 password,
                 ffdc_config,
                 location,
                 remote_type,
                 remote_protocol):
        r"""
        Description of argument(s):

        hostname                name/ip of the targeted (remote) system
        username                user on the targeted system with access to FFDC files
        password                password for user on targeted system
        ffdc_config             configuration file listing commands and files for FFDC
        location                where to store collected FFDC
        remote_type             os type of the remote host

        """
        if self.verify_script_env():
            self.hostname = hostname
            self.username = username
            self.password = password
            self.ffdc_config = ffdc_config
            self.location = location
            self.ssh_remoteclient = None
            self.tn_remoteclient = None
            self.ffdc_dir_path = ""
            self.ffdc_prefix = ""
            self.target_type = remote_type.upper()
            self.remote_protocol = remote_protocol.upper()
        else:
            sys.exit(-1)

    def verify_script_env(self):

        # Import to log version
        import click
        import paramiko

        run_env_ok = True

        redfishtool_version = self.run_redfishtool('-V').split(' ')[2].strip('\n')
        ipmitool_version = self.run_ipmitool('-V').split(' ')[2]

        print("\n\t---- Script host environment ----")
        print("\t{:<10}  {:<10}".format('Script hostname', os.uname()[1]))
        print("\t{:<10}  {:<10}".format('Script host os', platform.platform()))
        print("\t{:<10}  {:>10}".format('Python', platform.python_version()))
        print("\t{:<10}  {:>10}".format('PyYAML', yaml.__version__))
        print("\t{:<10}  {:>10}".format('click', click.__version__))
        print("\t{:<10}  {:>10}".format('paramiko', paramiko.__version__))
        print("\t{:<10}  {:>9}".format('redfishtool', redfishtool_version))
        print("\t{:<10}  {:>12}".format('ipmitool', ipmitool_version))

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
            print("\n\t[Check] %s is ping-able.\t\t [OK]" % self.hostname)
            return True
        else:
            print("\n>>>>>\tERROR: %s is not ping-able. FFDC collection aborted.\n" % self.hostname)
            sys.exit(-1)

    def inspect_target_machine_type(self, working_protocol_list):
        r"""
        Attempt to fetch OS Type from remote host

        Description of argument(s):

        working_protocol_list    List of verified remote host
                                 communication protocols
        """

        if 'SSH' in working_protocol_list:
            self.inspect_target_machine_type_ssh()
        elif 'TELNET' in working_protocol_list:
            self.inspect_target_machine_type_tn()
        else:
            print("\t[WARN] No SSH or Telnet to %s.\n" % self.target_type)
            print("\t[WARN] Will do as requested.\n")

    def inspect_target_machine_type_tn(self):

        r"""
        Attempt to fetch OS Type from remote host using telnet

        """

        result = self.tn_remoteclient.execute_command('uname -a')
        if result:
            print("\n\t[INFO] %s uname -a\n" % self.hostname)
            print("\t\t %s" % result)

            result_list = []
            result_list.append(result)
            user_target_type = self.target_type
            if self.find_os_type(result_list, 'AIX').split(' ')[0].upper():
                self.target_type = 'AIX'
            elif self.find_os_type(result_list, 'FSP').split(' ')[0].upper():
                self.target_type = 'FSP'

            if user_target_type != self.target_type:
                print("\n\t[WARN] user request %s does not match remote host type %s.\n"
                      % (user_target_type, self.target_type))
                print("\t[WARN] FFDC collection continues for %s.\n" % self.target_type)

    def inspect_target_machine_type_ssh(self):
        r"""
        Inspect remote host os-release or uname using ssh.

        """
        command = "cat /etc/os-release"
        response = self.ssh_remoteclient.execute_command(command)
        if response:
            print("\n\t[INFO] %s /etc/os-release\n" % self.hostname)
            for each_info in response:
                print("\t\t %s" % each_info)
            identity = self.find_os_type(response, 'ID').split('=')[1].upper()
        else:
            response = self.ssh_remoteclient.execute_command('uname -a')
            print("\n\t[INFO] %s uname -a\n" % self.hostname)
            print("\t\t %s" % ' '.join(response))
            identity = self.find_os_type(response, 'AIX').split(' ')[0].upper()

            # If OS does not have /etc/os-release and is not AIX,
            # script does not yet know what to do.
            if not identity:
                print(">>>>>\tERROR: Script does not yet know about %s" % ' '.join(response))
                sys.exit(-1)

        if (self.target_type not in identity):

            user_target_type = self.target_type
            self.target_type = ""
            for each_os in FFDCCollector.supported_oses:
                if each_os in identity:
                    self.target_type = each_os
                    break

            # If OS in not one of ['OPENBMC', 'RHEL', 'AIX', 'UBUNTU', 'FSP']
            # script does not yet know what to do.
            if not self.target_type:
                print(">>>>>\tERROR: Script does not yet know about %s" % identity)
                sys.exit(-1)

            print("\n\t[WARN] user request %s does not match remote host type %s.\n"
                  % (user_target_type, self.target_type))
            print("\t[WARN] FFDC collection continues for %s.\n" % self.target_type)

        r"""
        Inspect remote host os-release or uname.

        """
        command = "cat /etc/os-release"
        response = self.ssh_remoteclient.execute_command(command)
        if response:
            print("\n\t[INFO] %s /etc/os-release\n" % self.hostname)
            for each_info in response:
                print("\t\t %s" % each_info)
            identity = self.find_os_type(response, 'ID').split('=')[1].upper()
        else:
            response = self.ssh_remoteclient.execute_command('uname -a')
            print("\n\t[INFO] %s uname -a\n" % self.hostname)
            print("\t\t %s" % ' '.join(response))
            identity = self.find_os_type(response, 'AIX').split(' ')[0].upper()

            # If OS does not have /etc/os-release and is not AIX,
            # script does not yet know what to do.
            if not identity:
                print(">>>>>\tERROR: Script does not yet know about %s" % ' '.join(response))
                sys.exit(-1)

        if (self.target_type not in identity):

            user_target_type = self.target_type
            self.target_type = ""
            for each_os in FFDCCollector.supported_oses:
                if each_os in identity:
                    self.target_type = each_os
                    break

            # If OS in not one of ['OPENBMC', 'RHEL', 'AIX', 'UBUNTU']
            # script does not yet know what to do.
            if not self.target_type:
                print(">>>>>\tERROR: Script does not yet know about %s" % identity)
                sys.exit(-1)

            print("\n\t[WARN] user request %s does not match remote host type %s.\n"
                  % (user_target_type, self.target_type))
            print("\t[WARN] FFDC collection continues for %s.\n" % self.target_type)

    def find_os_type(self,
                     listing_from_os,
                     key):
        r"""
        Return OS information with the requested key

        Description of argument(s):

        listing_from_os    list of information returns from OS command
        key                key of the desired data

        """

        for each_item in listing_from_os:
            if key.upper() in each_item.upper():
                return each_item.upper()
        return ''

    def collect_ffdc(self):
        r"""
        Initiate FFDC Collection depending on requested protocol.

        """

        print("\n\t---- Start communicating with %s ----" % self.hostname)
        working_protocol_list = []
        if self.target_is_pingable():
            # Check supported protocol ping,ssh, redfish are working.
            if self.ssh_to_target_system():
                working_protocol_list.append("SSH")
                working_protocol_list.append("SCP")

            # Redfish
            if self.verify_redfish():
                working_protocol_list.append("REDFISH")
                print("\n\t[Check] %s Redfish Service.\t\t [OK]" % self.hostname)
            else:
                print("\n\t[Check] %s Redfish Service.\t\t [NOT AVAILABLE]" % self.hostname)

            # Impi
            if self.verify_ipmi():
                working_protocol_list.append("IPMI")
                print("\n\t[Check] %s IPMI LAN Service.\t\t [OK]" % self.hostname)
            else:
                print("\n\t[Check] %s IPMI LAN Service.\t\t [NOT AVAILABLE]" % self.hostname)

            # Telnet
            if self.telnet_to_target_system():
                working_protocol_list.append("TELNET")

            # Verify top level directory exists for storage
            self.validate_local_store(self.location)
            self.inspect_target_machine_type(working_protocol_list)
            print("\n\t---- Completed protocol pre-requisite check ----\n")

            if ((self.remote_protocol not in working_protocol_list) and (self.remote_protocol != 'ALL')):
                print("\n\tWorking protocol list: %s" % working_protocol_list)
                print(
                    '>>>>>\tERROR: Requested protocol %s is not in working protocol list.\n'
                    % self.remote_protocol)
                sys.exit(-1)
            else:
                self.generate_ffdc(working_protocol_list)

    def ssh_to_target_system(self):
        r"""
        Open a ssh connection to targeted system.

        """

        self.ssh_remoteclient = SSHRemoteclient(self.hostname,
                                                self.username,
                                                self.password)

        if self.ssh_remoteclient.ssh_remoteclient_login():
            print("\n\t[Check] %s SSH connection established.\t [OK]" % self.hostname)

            # Check scp connection.
            # If scp connection fails,
            # continue with FFDC generation but skip scp files to local host.
            self.ssh_remoteclient.scp_connection()
            return True
        else:
            print("\n\t[Check] %s SSH connection.\t [NOT AVAILABLE]" % self.hostname)
            return False

    def telnet_to_target_system(self):
        r"""
        Open a telnet connection to targeted system.

        """

        self.tn_remoteclient = TelnetRemoteclient(self.hostname,
                                                  self.username,
                                                  self.password)

        if self.tn_remoteclient.tn_remoteclient_login():
            print("\n\t[Check] %s Telnet connection established.\t [OK]" % self.hostname)
            return True
        else:
            print("\n\t[Check] %s Telnet connection.\t [NOT AVAILABLE]" % self.hostname)
            return False

    def generate_ffdc(self, working_protocol_list):
        r"""
        Determine actions based on remote host type

        Description of argument(s):
        working_protocol_list    list of confirmed working protocols to connect to remote host.
        """

        print("\n\t---- Executing commands on " + self.hostname + " ----")
        print("\n\tWorking protocol list: %s" % working_protocol_list)
        with open(self.ffdc_config, 'r') as file:
            ffdc_actions = yaml.load(file, Loader=yaml.FullLoader)

        # Set prefix values for scp files and directory.
        # Since the time stamp is at second granularity, these values are set here
        # to be sure that all files for this run will have same timestamps
        # and they will be saved in the same directory.
        # self.location == local system for now
        self.set_ffdc_defaults()

        for machine_type in ffdc_actions.keys():

            if machine_type == self.target_type:

                if (self.remote_protocol == 'SSH' or self.remote_protocol == 'ALL') \
                   and (ffdc_actions[machine_type]['PROTOCOL'][0] == 'SSH') \
                   and ('SSH' in working_protocol_list):
                    self.protocol_ssh(ffdc_actions, machine_type)

                if (self.remote_protocol == 'TELNET' or self.remote_protocol == 'ALL') \
                   and (ffdc_actions[machine_type]['PROTOCOL'][0] == 'TELNET') \
                   and ('TELNET' in working_protocol_list):
                    self.protocol_telnet(ffdc_actions, machine_type)

                if self.target_type == 'OPENBMC':
                    if self.remote_protocol == 'REDFISH' or self.remote_protocol == 'ALL':
                        self.protocol_redfish(ffdc_actions, 'OPENBMC_REDFISH')

                    if self.remote_protocol == 'IPMI' or self.remote_protocol == 'ALL':
                        self.protocol_ipmi(ffdc_actions, 'OPENBMC_IPMI')

        # Close network connections after collecting all files
        self.ssh_remoteclient.ssh_remoteclient_disconnect()
        self.tn_remoteclient.tn_remoteclient_disconnect()

    def protocol_ssh(self,
                     ffdc_actions,
                     machine_type):
        r"""
        Perform actions using SSH and SCP protocols.

        Description of argument(s):
        ffdc_actions        List of actions from ffdc_config.yaml.
        machine_type        OS Type of remote host.
        """

        # For OPENBMC collect general system info.
        if self.target_type == 'OPENBMC':

            self.collect_and_copy_ffdc(ffdc_actions['GENERAL'],
                                       form_filename=True)
            self.group_copy(ffdc_actions['OPENBMC_DUMPS'])

        # For RHEL and UBUNTU, collect common Linux OS FFDC.
        if self.target_type == 'RHEL' \
           or self.target_type == 'UBUNTU':

            self.collect_and_copy_ffdc(ffdc_actions['LINUX'])

        # Collect remote host specific FFDC.
        self.collect_and_copy_ffdc(ffdc_actions[machine_type])

    def protocol_redfish(self,
                         ffdc_actions,
                         machine_type):
        r"""
        Perform actions using Redfish protocol.

        Description of argument(s):
        ffdc_actions        List of actions from ffdc_config.yaml.
        machine_type        OS Type of remote host.
        """

        print("\n\t[Run] Executing commands to %s using %s" % (self.hostname, 'REDFISH'))
        redfish_files_saved = []
        progress_counter = 0
        list_of_URL = ffdc_actions[machine_type]['URL']
        for index, each_url in enumerate(list_of_URL, start=0):
            redfish_parm = '-u ' + self.username + ' -p ' + self.password + ' -r ' \
                           + self.hostname + ' -S Always raw GET ' + each_url

            result = self.run_redfishtool(redfish_parm)
            if result:
                try:
                    targ_file = ffdc_actions[machine_type]['FILES'][index]
                except IndexError:
                    targ_file = each_url.split('/')[-1]
                    print("\n\t[WARN] Missing filename to store data from redfish URL %s." % each_url)
                    print("\t[WARN] Data will be stored in %s." % targ_file)

                targ_file_with_path = (self.ffdc_dir_path
                                       + self.ffdc_prefix
                                       + targ_file)

                # Creates a new file
                with open(targ_file_with_path, 'w') as fp:
                    fp.write(result)
                    fp.close
                    redfish_files_saved.append(targ_file)

            progress_counter += 1
            self.print_progress(progress_counter)

        print("\n\t[Run] Commands execution completed.\t\t [OK]")

        for file in redfish_files_saved:
            print("\n\t\tSuccessfully save file " + file + ".")

    def protocol_ipmi(self,
                      ffdc_actions,
                      machine_type):
        r"""
        Perform actions using ipmitool over LAN protocol.

        Description of argument(s):
        ffdc_actions        List of actions from ffdc_config.yaml.
        machine_type        OS Type of remote host.
        """

        print("\n\t[Run] Executing commands to %s using %s" % (self.hostname, 'IPMI'))
        ipmi_files_saved = []
        progress_counter = 0
        list_of_cmd = ffdc_actions[machine_type]['COMMANDS']
        for index, each_cmd in enumerate(list_of_cmd, start=0):
            ipmi_parm = '-U ' + self.username + ' -P ' + self.password + ' -H ' \
                + self.hostname + ' ' + each_cmd

            result = self.run_ipmitool(ipmi_parm)
            if result:
                try:
                    targ_file = ffdc_actions[machine_type]['FILES'][index]
                except IndexError:
                    targ_file = each_cmd
                    print("\n\t[WARN] Missing filename to store data from IPMI %s." % each_cmd)
                    print("\t[WARN] Data will be stored in %s." % targ_file)

                targ_file_with_path = (self.ffdc_dir_path
                                       + self.ffdc_prefix
                                       + targ_file)

                # Creates a new file
                with open(targ_file_with_path, 'w') as fp:
                    fp.write(result)
                    fp.close
                    ipmi_files_saved.append(targ_file)

            progress_counter += 1
            self.print_progress(progress_counter)

        print("\n\t[Run] Commands execution completed.\t\t [OK]")

        for file in ipmi_files_saved:
            print("\n\t\tSuccessfully save file " + file + ".")

    def protocol_telnet(self,
                        ffdc_actions,
                        machine_type):
        r"""
        Perform actions using telnet protocol.

        Description of argument(s):
        ffdc_actions        List of actions from ffdc_config.yaml.
        machine_type        OS Type of remote host.
        """

        print("\n\t[Run] Executing commands on %s using %s" % (self.hostname, 'TELNET'))
        telnet_files_saved = []
        progress_counter = 0
        list_of_commands = ffdc_actions[machine_type]['COMMANDS']
        for index, each_cmd in enumerate(list_of_commands, start=0):
            result = self.tn_remoteclient.execute_command(each_cmd)
            if result:
                try:
                    targ_file = ffdc_actions[machine_type]['FILES'][index]
                except IndexError:
                    targ_file = each_cmd
                    print("\n\t[WARN] Missing filename to store data from telnet %s." % each_cmd)
                    print("\t[WARN] Data will be stored in %s." % targ_file)

                targ_file_with_path = (self.ffdc_dir_path
                                       + self.ffdc_prefix
                                       + targ_file)

                # Creates a new file
                with open(targ_file_with_path, 'w') as fp:
                    fp.write(result)
                    fp.close
                    telnet_files_saved.append(targ_file)

            progress_counter += 1
            self.print_progress(progress_counter)

        print("\n\t[Run] Commands execution completed.\t\t [OK]")

        for file in telnet_files_saved:
            print("\n\t\tSuccessfully save file " + file + ".")

    def collect_and_copy_ffdc(self,
                              ffdc_actions_for_machine_type,
                              form_filename=False):
        r"""
        Send commands in ffdc_config file to targeted system.

        Description of argument(s):
        ffdc_actions_for_machine_type    commands and files for the selected remote host type.
        form_filename                    if true, pre-pend self.target_type to filename
        """

        print("\n\t[Run] Executing commands on %s using %s"
              % (self.hostname, ffdc_actions_for_machine_type['PROTOCOL'][0]))
        list_of_commands = ffdc_actions_for_machine_type['COMMANDS']
        progress_counter = 0
        for command in list_of_commands:
            if form_filename:
                command = str(command % self.target_type)
            self.ssh_remoteclient.execute_command(command)
            progress_counter += 1
            self.print_progress(progress_counter)

        print("\n\t[Run] Commands execution completed.\t\t [OK]")

        if self.ssh_remoteclient.scpclient:
            print("\n\n\tCopying FFDC files from remote system %s.\n" % self.hostname)

            # Retrieving files from target system
            list_of_files = ffdc_actions_for_machine_type['FILES']
            self.scp_ffdc(self.ffdc_dir_path, self.ffdc_prefix, form_filename, list_of_files)
        else:
            print("\n\n\tSkip copying FFDC files from remote system %s.\n" % self.hostname)

    def group_copy(self,
                   ffdc_actions_for_machine_type):
        r"""
        scp group of files (wild card) from remote host.

        Description of argument(s):
        ffdc_actions_for_machine_type    commands and files for the selected remote host type.
        """
        if self.ssh_remoteclient.scpclient:
            print("\n\tCopying DUMP files from remote system %s.\n" % self.hostname)

            # Retrieving files from target system, if any
            list_of_files = ffdc_actions_for_machine_type['FILES']

            for filename in list_of_files:
                command = 'ls -AX ' + filename
                response = self.ssh_remoteclient.execute_command(command)
                # self.ssh_remoteclient.scp_file_from_remote() completed without exception,
                # if any
                if response:
                    scp_result = self.ssh_remoteclient.scp_file_from_remote(filename, self.ffdc_dir_path)
                    if scp_result:
                        print("\t\tSuccessfully copied from " + self.hostname + ':' + filename)
                else:
                    print("\t\tThere is no  " + filename)

        else:
            print("\n\n\tSkip copying files from remote system %s.\n" % self.hostname)

    def scp_ffdc(self,
                 targ_dir_path,
                 targ_file_prefix,
                 form_filename,
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

        progress_counter = 0
        for filename in file_list:
            if form_filename:
                filename = str(filename % self.target_type)
            source_file_path = filename
            targ_file_path = targ_dir_path + targ_file_prefix + filename.split('/')[-1]

            # self.ssh_remoteclient.scp_file_from_remote() completed without exception,
            # add file to the receiving file list.
            scp_result = self.ssh_remoteclient.scp_file_from_remote(source_file_path, targ_file_path)

            if not quiet:
                if scp_result:
                    print("\t\tSuccessfully copied from " + self.hostname + ':' + source_file_path + ".\n")
                else:
                    print("\t\tFail to copy from " + self.hostname + ':' + source_file_path + ".\n")
            else:
                progress_counter += 1
                self.print_progress(progress_counter)

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

    def verify_redfish(self):
        r"""
        Verify remote host has redfish service active

        """
        redfish_parm = '-u ' + self.username + ' -p ' + self.password + ' -r ' \
                       + self.hostname + ' -S Always raw GET /redfish/v1/'
        return(self.run_redfishtool(redfish_parm, True))

    def verify_ipmi(self):
        r"""
        Verify remote host has IPMI LAN service active

        """
        ipmi_parm = '-U ' + self.username + ' -P ' + self.password + ' -H ' \
            + self.hostname + ' power status'
        return(self.run_ipmitool(ipmi_parm, True))

    def run_redfishtool(self,
                        parms_string,
                        quiet=False):
        r"""
        Run CLI redfishtool

        Description of variable:
        parms_string         redfishtool subcommand and options.
        quiet                do not print redfishtool error message if True
        """

        result = subprocess.run(['redfishtool ' + parms_string],
                                stdout=subprocess.PIPE,
                                stderr=subprocess.PIPE,
                                shell=True,
                                universal_newlines=True)

        if result.stderr and not quiet:
            print('\n\t\tERROR with redfishtool ' + parms_string)
            print('\t\t' + result.stderr)

        return result.stdout

    def run_ipmitool(self,
                     parms_string,
                     quiet=False):
        r"""
        Run CLI IPMI tool.

        Description of variable:
        parms_string         ipmitool subcommand and options.
        quiet                do not print redfishtool error message if True
        """

        result = subprocess.run(['ipmitool -I lanplus -C 17 ' + parms_string],
                                stdout=subprocess.PIPE,
                                stderr=subprocess.PIPE,
                                shell=True,
                                universal_newlines=True)

        if result.stderr and not quiet:
            print('\n\t\tERROR with ipmitool -I lanplus -C 17 ' + parms_string)
            print('\t\t' + result.stderr)

        return result.stdout
