#!/usr/bin/env python

r"""
See class prolog below for details.
"""

import os
import sys
import yaml
import time
import logging
import platform
from errno import EACCES, EPERM
import subprocess
from ssh_utility import SSHRemoteclient
from telnet_utility import TelnetRemoteclient


class FFDCCollector:

    r"""
    Sends commands from configuration file to the targeted system to collect log files.
    Fetch and store generated files at the specified location.

    """

    def __init__(self,
                 hostname,
                 username,
                 password,
                 ffdc_config,
                 location,
                 remote_type,
                 remote_protocol,
                 log_level):
        r"""
        Description of argument(s):

        hostname                name/ip of the targeted (remote) system
        username                user on the targeted system with access to FFDC files
        password                password for user on targeted system
        ffdc_config             configuration file listing commands and files for FFDC
        location                where to store collected FFDC
        remote_type             os type of the remote host

        """

        self.hostname = hostname
        self.username = username
        self.password = password
        self.ffdc_config = ffdc_config
        self.location = location + "/" + remote_type.upper()
        self.ssh_remoteclient = None
        self.telnet_remoteclient = None
        self.ffdc_dir_path = ""
        self.ffdc_prefix = ""
        self.target_type = remote_type.upper()
        self.remote_protocol = remote_protocol.upper()
        self.start_time = 0
        self.elapsed_time = ''
        self.logger = None

        # Set prefix values for scp files and directory.
        # Since the time stamp is at second granularity, these values are set here
        # to be sure that all files for this run will have same timestamps
        # and they will be saved in the same directory.
        # self.location == local system for now
        self.set_ffdc_defaults()

        # Logger for this run.  Need to be after set_ffdc_defaults()
        self.script_logging(getattr(logging, log_level.upper()))

        # Verify top level directory exists for storage
        self.validate_local_store(self.location)

        if self.verify_script_env():
            # Load default or user define YAML configuration file.
            with open(self.ffdc_config, 'r') as file:
                self.ffdc_actions = yaml.load(file, Loader=yaml.FullLoader)

            if self.target_type not in self.ffdc_actions.keys():
                self.logger.error(
                    "\n\tERROR: %s is not listed in %s.\n\n" % (self.target_type, self.ffdc_config))
                sys.exit(-1)
        else:
            sys.exit(-1)

    def verify_script_env(self):

        # Import to log version
        import click
        import paramiko

        run_env_ok = True

        redfishtool_version = self.run_redfishtool('-V').split(' ')[2].strip('\n')
        ipmitool_version = self.run_ipmitool('-V').split(' ')[2]

        self.logger.info("\n\t---- Script host environment ----")
        self.logger.info("\t{:<10}  {:<10}".format('Script hostname', os.uname()[1]))
        self.logger.info("\t{:<10}  {:<10}".format('Script host os', platform.platform()))
        self.logger.info("\t{:<10}  {:>10}".format('Python', platform.python_version()))
        self.logger.info("\t{:<10}  {:>10}".format('PyYAML', yaml.__version__))
        self.logger.info("\t{:<10}  {:>10}".format('click', click.__version__))
        self.logger.info("\t{:<10}  {:>10}".format('paramiko', paramiko.__version__))
        self.logger.info("\t{:<10}  {:>9}".format('redfishtool', redfishtool_version))
        self.logger.info("\t{:<10}  {:>12}".format('ipmitool', ipmitool_version))

        if eval(yaml.__version__.replace('.', ',')) < (5, 4, 1):
            self.logger.error("\n\tERROR: Python or python packages do not meet minimum version requirement.")
            self.logger.error("\tERROR: PyYAML version 5.4.1 or higher is needed.\n")
            run_env_ok = False

        self.logger.info("\t---- End script host environment ----")
        return run_env_ok

    def script_logging(self,
                       log_level_attr):
        r"""
        Create logger

        """
        self.logger = logging.getLogger()
        self.logger.setLevel(log_level_attr)
        log_file_handler = logging.FileHandler(self.ffdc_dir_path + "collector.log")

        stdout_handler = logging.StreamHandler(sys.stdout)
        self.logger.addHandler(log_file_handler)
        self.logger.addHandler(stdout_handler)

        # Turn off paramiko INFO logging
        logging.getLogger("paramiko").setLevel(logging.WARNING)

    def target_is_pingable(self):
        r"""
        Check if target system is ping-able.

        """
        response = os.system("ping -c 1 %s  2>&1 >/dev/null" % self.hostname)
        if response == 0:
            self.logger.info("\n\t[Check] %s is ping-able.\t\t [OK]" % self.hostname)
            return True
        else:
            self.logger.error(
                "\n>>>>>\tERROR: %s is not ping-able. FFDC collection aborted.\n" % self.hostname)
            sys.exit(-1)

    def collect_ffdc(self):
        r"""
        Initiate FFDC Collection depending on requested protocol.

        """

        self.logger.info("\n\t---- Start communicating with %s ----" % self.hostname)
        self.start_time = time.time()
        working_protocol_list = []
        if self.target_is_pingable():
            # Check supported protocol ping,ssh, redfish are working.
            if self.ssh_to_target_system():
                working_protocol_list.append("SSH")
                working_protocol_list.append("SCP")

            # Redfish
            if self.verify_redfish():
                working_protocol_list.append("REDFISH")
                self.logger.info("\n\t[Check] %s Redfish Service.\t\t [OK]" % self.hostname)
            else:
                self.logger.info("\n\t[Check] %s Redfish Service.\t\t [NOT AVAILABLE]" % self.hostname)

            # IPMI
            if self.verify_ipmi():
                working_protocol_list.append("IPMI")
                self.logger.info("\n\t[Check] %s IPMI LAN Service.\t\t [OK]" % self.hostname)
            else:
                self.logger.info("\n\t[Check] %s IPMI LAN Service.\t\t [NOT AVAILABLE]" % self.hostname)

            # Telnet
            if self.telnet_to_target_system():
                working_protocol_list.append("TELNET")

            # Verify top level directory exists for storage
            self.validate_local_store(self.location)
            self.logger.info("\n\t---- Completed protocol pre-requisite check ----\n")

            if ((self.remote_protocol not in working_protocol_list) and (self.remote_protocol != 'ALL')):
                self.logger.info("\n\tWorking protocol list: %s" % working_protocol_list)
                self.logger.error(
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
            self.logger.info("\n\t[Check] %s SSH connection established.\t [OK]" % self.hostname)

            # Check scp connection.
            # If scp connection fails,
            # continue with FFDC generation but skip scp files to local host.
            self.ssh_remoteclient.scp_connection()
            return True
        else:
            self.logger.info("\n\t[Check] %s SSH connection.\t [NOT AVAILABLE]" % self.hostname)
            return False

    def telnet_to_target_system(self):
        r"""
        Open a telnet connection to targeted system.
        """
        self.telnet_remoteclient = TelnetRemoteclient(self.hostname,
                                                      self.username,
                                                      self.password)
        if self.telnet_remoteclient.tn_remoteclient_login():
            self.logger.info("\n\t[Check] %s Telnet connection established.\t [OK]" % self.hostname)
            return True
        else:
            self.logger.info("\n\t[Check] %s Telnet connection.\t [NOT AVAILABLE]" % self.hostname)
            return False

    def generate_ffdc(self, working_protocol_list):
        r"""
        Determine actions based on remote host type

        Description of argument(s):
        working_protocol_list    list of confirmed working protocols to connect to remote host.
        """

        self.logger.info("\n\t---- Executing commands on " + self.hostname + " ----")
        self.logger.info("\n\tWorking protocol list: %s" % working_protocol_list)

        ffdc_actions = self.ffdc_actions

        for machine_type in ffdc_actions.keys():
            if self.target_type != machine_type:
                continue

            self.logger.info("\n\tFFDC Path: %s " % self.ffdc_dir_path)
            self.logger.info("\tSystem Type: %s" % machine_type)
            for k, v in ffdc_actions[machine_type].items():

                if self.remote_protocol != ffdc_actions[machine_type][k]['PROTOCOL'][0] \
                        and self.remote_protocol != 'ALL':
                    continue

                if ffdc_actions[machine_type][k]['PROTOCOL'][0] == 'SSH' \
                   or ffdc_actions[machine_type][k]['PROTOCOL'][0] == 'SCP':
                    if 'SSH' in working_protocol_list \
                       or 'SCP' in working_protocol_list:
                        self.protocol_ssh(ffdc_actions, machine_type, k)
                    else:
                        self.logger.error("\n\tERROR: SSH or SCP is not available for %s." % self.hostname)

                if ffdc_actions[machine_type][k]['PROTOCOL'][0] == 'TELNET':
                    if 'TELNET' in working_protocol_list:
                        self.protocol_telnet(ffdc_actions, machine_type, k)
                    else:
                        self.logger.error("\n\tERROR: TELNET is not available for %s." % self.hostname)

                if ffdc_actions[machine_type][k]['PROTOCOL'][0] == 'REDFISH':
                    if 'REDFISH' in working_protocol_list:
                        self.protocol_redfish(ffdc_actions, machine_type, k)
                    else:
                        self.logger.error("\n\tERROR: REDFISH is not available for %s." % self.hostname)

                if ffdc_actions[machine_type][k]['PROTOCOL'][0] == 'IPMI':
                    if 'IPMI' in working_protocol_list:
                        self.protocol_ipmi(ffdc_actions, machine_type, k)
                    else:
                        self.logger.error("\n\tERROR: IMPI is not available for %s." % self.hostname)

        # Close network connection after collecting all files
        self.elapsed_time = time.strftime("%H:%M:%S", time.gmtime(time.time() - self.start_time))
        self.ssh_remoteclient.ssh_remoteclient_disconnect()
        self.telnet_remoteclient.tn_remoteclient_disconnect()

    def protocol_ssh(self,
                     ffdc_actions,
                     machine_type,
                     sub_type):
        r"""
        Perform actions using SSH and SCP protocols.

        Description of argument(s):
        ffdc_actions        List of actions from ffdc_config.yaml.
        machine_type        OS Type of remote host.
        sub_type            Group type of commands.
        """

        if sub_type == 'DUMP_LOGS':
            self.group_copy(ffdc_actions[machine_type][sub_type])
        else:
            self.collect_and_copy_ffdc(ffdc_actions[machine_type][sub_type])

    def protocol_telnet(self,
                        ffdc_actions,
                        machine_type,
                        sub_type):
        r"""
        Perform actions using telnet protocol.
        Description of argument(s):
        ffdc_actions        List of actions from ffdc_config.yaml.
        machine_type        OS Type of remote host.
        """
        self.logger.info("\n\t[Run] Executing commands on %s using %s" % (self.hostname, 'TELNET'))
        telnet_files_saved = []
        progress_counter = 0
        list_of_commands = ffdc_actions[machine_type][sub_type]['COMMANDS']
        for index, each_cmd in enumerate(list_of_commands, start=0):
            command_txt, command_timeout = self.unpack_command(each_cmd)
            result = self.telnet_remoteclient.execute_command(command_txt, command_timeout)
            if result:
                try:
                    targ_file = ffdc_actions[machine_type][sub_type]['FILES'][index]
                except IndexError:
                    targ_file = command_txt
                    self.logger.warning(
                        "\n\t[WARN] Missing filename to store data from telnet %s." % each_cmd)
                    self.logger.warning("\t[WARN] Data will be stored in %s." % targ_file)
                targ_file_with_path = (self.ffdc_dir_path
                                       + self.ffdc_prefix
                                       + targ_file)
                # Creates a new file
                with open(targ_file_with_path, 'wb') as fp:
                    fp.write(result)
                    fp.close
                    telnet_files_saved.append(targ_file)
            progress_counter += 1
            self.print_progress(progress_counter)
        self.logger.info("\n\t[Run] Commands execution completed.\t\t [OK]")
        for file in telnet_files_saved:
            self.logger.info("\n\t\tSuccessfully save file " + file + ".")

    def protocol_redfish(self,
                         ffdc_actions,
                         machine_type,
                         sub_type):
        r"""
        Perform actions using Redfish protocol.

        Description of argument(s):
        ffdc_actions        List of actions from ffdc_config.yaml.
        machine_type        OS Type of remote host.
        sub_type            Group type of commands.
        """

        self.logger.info("\n\t[Run] Executing commands to %s using %s" % (self.hostname, 'REDFISH'))
        redfish_files_saved = []
        progress_counter = 0
        list_of_URL = ffdc_actions[machine_type][sub_type]['URL']
        for index, each_url in enumerate(list_of_URL, start=0):
            redfish_parm = '-u ' + self.username + ' -p ' + self.password + ' -r ' \
                           + self.hostname + ' -S Always raw GET ' + each_url

            result = self.run_redfishtool(redfish_parm)
            if result:
                try:
                    targ_file = self.get_file_list(ffdc_actions[machine_type][sub_type])[index]
                except IndexError:
                    targ_file = each_url.split('/')[-1]
                    self.logger.warning(
                        "\n\t[WARN] Missing filename to store data from redfish URL %s." % each_url)
                    self.logger.warning("\t[WARN] Data will be stored in %s." % targ_file)

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

        self.logger.info("\n\t[Run] Commands execution completed.\t\t [OK]")

        for file in redfish_files_saved:
            self.logger.info("\n\t\tSuccessfully save file " + file + ".")

    def protocol_ipmi(self,
                      ffdc_actions,
                      machine_type,
                      sub_type):
        r"""
        Perform actions using ipmitool over LAN protocol.

        Description of argument(s):
        ffdc_actions        List of actions from ffdc_config.yaml.
        machine_type        OS Type of remote host.
        sub_type            Group type of commands.
        """

        self.logger.info("\n\t[Run] Executing commands to %s using %s" % (self.hostname, 'IPMI'))
        ipmi_files_saved = []
        progress_counter = 0
        list_of_cmd = self.get_command_list(ffdc_actions[machine_type][sub_type])
        for index, each_cmd in enumerate(list_of_cmd, start=0):
            ipmi_parm = '-U ' + self.username + ' -P ' + self.password + ' -H ' \
                + self.hostname + ' ' + each_cmd

            result = self.run_ipmitool(ipmi_parm)
            if result:
                try:
                    targ_file = self.get_file_list(ffdc_actions[machine_type][sub_type])[index]
                except IndexError:
                    targ_file = each_cmd.split('/')[-1]
                    self.logger.warning("\n\t[WARN] Missing filename to store data from IPMI %s." % each_cmd)
                    self.logger.warning("\t[WARN] Data will be stored in %s." % targ_file)

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

        self.logger.info("\n\t[Run] Commands execution completed.\t\t [OK]")

        for file in ipmi_files_saved:
            self.logger.info("\n\t\tSuccessfully save file " + file + ".")

    def collect_and_copy_ffdc(self,
                              ffdc_actions_for_machine_type,
                              form_filename=False):
        r"""
        Send commands in ffdc_config file to targeted system.

        Description of argument(s):
        ffdc_actions_for_machine_type    commands and files for the selected remote host type.
        form_filename                    if true, pre-pend self.target_type to filename
        """

        # Executing commands, , if any
        self.ssh_execute_ffdc_commands(ffdc_actions_for_machine_type,
                                       form_filename)

        # Copying files
        if self.ssh_remoteclient.scpclient:
            self.logger.info("\n\n\tCopying FFDC files from remote system %s.\n" % self.hostname)

            # Retrieving files from target system
            list_of_files = self.get_file_list(ffdc_actions_for_machine_type)
            self.scp_ffdc(self.ffdc_dir_path, self.ffdc_prefix, form_filename, list_of_files)
        else:
            self.logger.info("\n\n\tSkip copying FFDC files from remote system %s.\n" % self.hostname)

    def get_command_list(self,
                         ffdc_actions_for_machine_type):
        r"""
        Fetch list of commands from configuration file

        Description of argument(s):
        ffdc_actions_for_machine_type    commands and files for the selected remote host type.
        """
        try:
            list_of_commands = ffdc_actions_for_machine_type['COMMANDS']
        except KeyError:
            list_of_commands = []
        return list_of_commands

    def get_file_list(self,
                      ffdc_actions_for_machine_type):
        r"""
        Fetch list of commands from configuration file

        Description of argument(s):
        ffdc_actions_for_machine_type    commands and files for the selected remote host type.
        """
        try:
            list_of_files = ffdc_actions_for_machine_type['FILES']
        except KeyError:
            list_of_files = []
        return list_of_files

    def unpack_command(self,
                       command):
        r"""
        Unpack command from config file

        Description of argument(s):
        command    Command from config file.
        """
        if isinstance(command, dict):
            command_txt = next(iter(command))
            command_timeout = next(iter(command.values()))
        elif isinstance(command, str):
            command_txt = command
            # Default command timeout 60 seconds
            command_timeout = 60

        return command_txt, command_timeout

    def ssh_execute_ffdc_commands(self,
                                  ffdc_actions_for_machine_type,
                                  form_filename=False):
        r"""
        Send commands in ffdc_config file to targeted system.

        Description of argument(s):
        ffdc_actions_for_machine_type    commands and files for the selected remote host type.
        form_filename                    if true, pre-pend self.target_type to filename
        """
        self.logger.info("\n\t[Run] Executing commands on %s using %s"
                         % (self.hostname, ffdc_actions_for_machine_type['PROTOCOL'][0]))

        list_of_commands = self.get_command_list(ffdc_actions_for_machine_type)
        # If command list is empty, returns
        if not list_of_commands:
            return

        progress_counter = 0
        for command in list_of_commands:
            command_txt, command_timeout = self.unpack_command(command)

            if form_filename:
                command_txt = str(command_txt % self.target_type)

            err, response = self.ssh_remoteclient.execute_command(command_txt, command_timeout)

            progress_counter += 1
            self.print_progress(progress_counter)

        self.logger.info("\n\t[Run] Commands execution completed.\t\t [OK]")

    def group_copy(self,
                   ffdc_actions_for_machine_type):
        r"""
        scp group of files (wild card) from remote host.

        Description of argument(s):
        ffdc_actions_for_machine_type    commands and files for the selected remote host type.
        """

        if self.ssh_remoteclient.scpclient:
            self.logger.info("\n\tCopying DUMP files from remote system %s.\n" % self.hostname)

            list_of_commands = self.get_command_list(ffdc_actions_for_machine_type)
            # If command list is empty, returns
            if not list_of_commands:
                return

            for command in list_of_commands:
                try:
                    filename = command.split(' ')[2]
                except IndexError:
                    self.logger.info("\t\tInvalid command %s for DUMP_LOGS block." % command)
                    continue

                err, response = self.ssh_remoteclient.execute_command(command)

                if response:
                    scp_result = self.ssh_remoteclient.scp_file_from_remote(filename, self.ffdc_dir_path)
                    if scp_result:
                        self.logger.info("\t\tSuccessfully copied from " + self.hostname + ':' + filename)
                else:
                    self.logger.info("\t\tThere is no " + filename)

        else:
            self.logger.info("\n\n\tSkip copying files from remote system %s.\n" % self.hostname)

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

            # If source file name contains wild card, copy filename as is.
            if '*' in source_file_path:
                scp_result = self.ssh_remoteclient.scp_file_from_remote(source_file_path, self.ffdc_dir_path)
            else:
                scp_result = self.ssh_remoteclient.scp_file_from_remote(source_file_path, targ_file_path)

            if not quiet:
                if scp_result:
                    self.logger.info(
                        "\t\tSuccessfully copied from " + self.hostname + ':' + source_file_path + ".\n")
                else:
                    self.logger.info(
                        "\t\tFail to copy from " + self.hostname + ':' + source_file_path + ".\n")
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
                os.makedirs(dir_path, 0o755)
            except (IOError, OSError) as e:
                # PermissionError
                if e.errno == EPERM or e.errno == EACCES:
                    self.logger.error(
                        '>>>>>\tERROR: os.makedirs %s failed with PermissionError.\n' % dir_path)
                else:
                    self.logger.error(
                        '>>>>>\tERROR: os.makedirs %s failed with %s.\n' % (dir_path, e.strerror))
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
            self.logger.info('\n\t\tERROR with redfishtool ' + parms_string)
            self.logger.info('\t\t' + result.stderr)

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
            self.logger.info('\n\t\tERROR with ipmitool -I lanplus -C 17 ' + parms_string)
            self.logger.info('\t\t' + result.stderr)

        return result.stdout
