#!/usr/bin/env python3

r"""
See class prolog below for details.
"""

import os
import re
import sys
import yaml
import json
import time
import logging
import platform
from errno import EACCES, EPERM
import subprocess
from ssh_utility import SSHRemoteclient
from telnet_utility import TelnetRemoteclient

r"""
User define plugins python functions.

It will imports files from directory plugins

plugins
├── file1.py
└── file2.py

Example how to define in YAML:
 - plugin:
   - plugin_name: plugin.foo_func.foo_func_yaml
     - plugin_args:
       - arg1
       - arg2
"""
abs_path = os.path.abspath(os.path.dirname(sys.argv[0]))
plugin_dir = abs_path + '/plugins'
try:
    for module in os.listdir(plugin_dir):
        if module == '__init__.py' or module[-3:] != '.py':
            continue
        plugin_module = "plugins." + module[:-3]
        # To access the module plugin.<module name>.<function>
        # Example: plugin.foo_func.foo_func_yaml()
        try:
            plugin = __import__(plugin_module, globals(), locals(), [], 0)
        except Exception as e:
            print("PLUGIN: Module import failed: %s" % module)
            pass
except FileNotFoundError as e:
    print("PLUGIN: %s" % e)
    pass

r"""
This is for plugin functions returning data or responses to the caller
in YAML plugin setup.

Example:

    - plugin:
      - plugin_name: version = plugin.ssh_execution.ssh_execute_cmd
      - plugin_args:
        - ${hostname}
        - ${username}
        - ${password}
        - "cat /etc/os-release | grep VERSION_ID | awk -F'=' '{print $2}'"
     - plugin:
        - plugin_name: plugin.print_vars.print_vars
        - plugin_args:
          - version

where first plugin "version" var is used by another plugin in the YAML
block or plugin

"""
global global_log_store_path
global global_plugin_dict
global global_plugin_list

# Hold the plugin return values in dict and plugin return vars in list.
# Dict is to reference and update vars processing in parser where as
# list is for current vars from the plugin block which needs processing.
global_plugin_dict = {}
global_plugin_list = []

# Hold the plugin return named declared if function returned values are list,dict.
# Refer this name list to look up the plugin dict for eval() args function
# Example ['version']
global_plugin_type_list = []

# Path where logs are to be stored or written.
global_log_store_path = ''

# Plugin error state defaults.
plugin_error_dict = {
    'exit_on_error': False,
    'continue_on_error': False,
}


class FFDCCollector:

    r"""
    Execute commands from configuration file to collect log files.
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
                 env_vars,
                 econfig,
                 log_level):
        r"""
        Description of argument(s):

        hostname            name/ip of the targeted (remote) system
        username            user on the targeted system with access to FFDC files
        password            password for user on targeted system
        ffdc_config         configuration file listing commands and files for FFDC
        location            where to store collected FFDC
        remote_type         os type of the remote host
        remote_protocol     Protocol to use to collect data
        env_vars            User define CLI env vars '{"key : "value"}'
        econfig             User define env vars YAML file

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
        self.env_vars = env_vars
        self.econfig = econfig
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
                try:
                    self.ffdc_actions = yaml.load(file, Loader=yaml.FullLoader)
                except yaml.YAMLError as e:
                    self.logger.error(e)
                    sys.exit(-1)

            if self.target_type not in self.ffdc_actions.keys():
                self.logger.error(
                    "\n\tERROR: %s is not listed in %s.\n\n" % (self.target_type, self.ffdc_config))
                sys.exit(-1)
        else:
            sys.exit(-1)

        # Load ENV vars from user.
        self.logger.info("\n\tENV: User define input YAML variables")
        self.env_dict = {}
        self. load_env()

    def verify_script_env(self):

        # Import to log version
        import click
        import paramiko

        run_env_ok = True

        redfishtool_version = self.run_tool_cmd('redfishtool -V').split(' ')[2].strip('\n')
        ipmitool_version = self.run_tool_cmd('ipmitool -V').split(' ')[2]

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
                "\n\tERROR: %s is not ping-able. FFDC collection aborted.\n" % self.hostname)
            sys.exit(-1)

    def collect_ffdc(self):
        r"""
        Initiate FFDC Collection depending on requested protocol.

        """

        self.logger.info("\n\t---- Start communicating with %s ----" % self.hostname)
        self.start_time = time.time()

        # Find the list of target and protocol supported.
        check_protocol_list = []
        config_dict = self.ffdc_actions

        for target_type in config_dict.keys():
            if self.target_type != target_type:
                continue

            for k, v in config_dict[target_type].items():
                if config_dict[target_type][k]['PROTOCOL'][0] not in check_protocol_list:
                    check_protocol_list.append(config_dict[target_type][k]['PROTOCOL'][0])

        self.logger.info("\n\t %s protocol type: %s" % (self.target_type, check_protocol_list))

        verified_working_protocol = self.verify_protocol(check_protocol_list)

        if verified_working_protocol:
            self.logger.info("\n\t---- Completed protocol pre-requisite check ----\n")

        # Verify top level directory exists for storage
        self.validate_local_store(self.location)

        if ((self.remote_protocol not in verified_working_protocol) and (self.remote_protocol != 'ALL')):
            self.logger.info("\n\tWorking protocol list: %s" % verified_working_protocol)
            self.logger.error(
                '\tERROR: Requested protocol %s is not in working protocol list.\n'
                % self.remote_protocol)
            sys.exit(-1)
        else:
            self.generate_ffdc(verified_working_protocol)

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

        config_dict = self.ffdc_actions
        for target_type in config_dict.keys():
            if self.target_type != target_type:
                continue

            self.logger.info("\n\tFFDC Path: %s " % self.ffdc_dir_path)
            global_plugin_dict['global_log_store_path'] = self.ffdc_dir_path
            self.logger.info("\tSystem Type: %s" % target_type)
            for k, v in config_dict[target_type].items():

                if self.remote_protocol not in working_protocol_list \
                        and self.remote_protocol != 'ALL':
                    continue

                protocol = config_dict[target_type][k]['PROTOCOL'][0]

                if protocol not in working_protocol_list:
                    continue

                if protocol in working_protocol_list:
                    if protocol == 'SSH' or protocol == 'SCP':
                        self.protocol_ssh(protocol, target_type, k)
                    elif protocol == 'TELNET':
                        self.protocol_telnet(target_type, k)
                    elif protocol == 'REDFISH' or protocol == 'IPMI' or protocol == 'SHELL':
                        self.protocol_execute(protocol, target_type, k)
                else:
                    self.logger.error("\n\tERROR: %s is not available for %s." % (protocol, self.hostname))

        # Close network connection after collecting all files
        self.elapsed_time = time.strftime("%H:%M:%S", time.gmtime(time.time() - self.start_time))
        if self.ssh_remoteclient:
            self.ssh_remoteclient.ssh_remoteclient_disconnect()
        if self.telnet_remoteclient:
            self.telnet_remoteclient.tn_remoteclient_disconnect()

    def protocol_ssh(self,
                     protocol,
                     target_type,
                     sub_type):
        r"""
        Perform actions using SSH and SCP protocols.

        Description of argument(s):
        protocol            Protocol to execute.
        target_type         OS Type of remote host.
        sub_type            Group type of commands.
        """

        if protocol == 'SCP':
            self.group_copy(self.ffdc_actions[target_type][sub_type])
        else:
            self.collect_and_copy_ffdc(self.ffdc_actions[target_type][sub_type])

    def protocol_telnet(self,
                        target_type,
                        sub_type):
        r"""
        Perform actions using telnet protocol.
        Description of argument(s):
        target_type          OS Type of remote host.
        """
        self.logger.info("\n\t[Run] Executing commands on %s using %s" % (self.hostname, 'TELNET'))
        telnet_files_saved = []
        progress_counter = 0
        list_of_commands = self.ffdc_actions[target_type][sub_type]['COMMANDS']
        for index, each_cmd in enumerate(list_of_commands, start=0):
            command_txt, command_timeout = self.unpack_command(each_cmd)
            result = self.telnet_remoteclient.execute_command(command_txt, command_timeout)
            if result:
                try:
                    targ_file = self.ffdc_actions[target_type][sub_type]['FILES'][index]
                except IndexError:
                    targ_file = command_txt
                    self.logger.warning(
                        "\n\t[WARN] Missing filename to store data from telnet %s." % each_cmd)
                    self.logger.warning("\t[WARN] Data will be stored in %s." % targ_file)
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
        self.logger.info("\n\t[Run] Commands execution completed.\t\t [OK]")
        for file in telnet_files_saved:
            self.logger.info("\n\t\tSuccessfully save file " + file + ".")

    def protocol_execute(self,
                         protocol,
                         target_type,
                         sub_type):
        r"""
        Perform actions for a given protocol.

        Description of argument(s):
        protocol            Protocol to execute.
        target_type         OS Type of remote host.
        sub_type            Group type of commands.
        """

        self.logger.info("\n\t[Run] Executing commands to %s using %s" % (self.hostname, protocol))
        executed_files_saved = []
        progress_counter = 0
        list_of_cmd = self.get_command_list(self.ffdc_actions[target_type][sub_type])
        for index, each_cmd in enumerate(list_of_cmd, start=0):
            plugin_call = False
            if isinstance(each_cmd, dict):
                if 'plugin' in each_cmd:
                    # If the error is set and plugin explicitly
                    # requested to skip execution on error..
                    if plugin_error_dict['exit_on_error'] and \
                            self.plugin_error_check(each_cmd['plugin']):
                        self.logger.info("\n\t[PLUGIN-ERROR] exit_on_error: %s" %
                                         plugin_error_dict['exit_on_error'])
                        self.logger.info("\t[PLUGIN-SKIP] %s" %
                                         each_cmd['plugin'][0])
                        continue
                    plugin_call = True
                    # call the plugin
                    self.logger.info("\n\t[PLUGIN-START]")
                    result = self.execute_plugin_block(each_cmd['plugin'])
                    self.logger.info("\t[PLUGIN-END]\n")
            else:
                each_cmd = self.yaml_env_and_plugin_vars_populate(each_cmd)

            if not plugin_call:
                result = self.run_tool_cmd(each_cmd)
            if result:
                try:
                    file_name = self.get_file_list(self.ffdc_actions[target_type][sub_type])[index]
                    # If file is specified as None.
                    if file_name == "None":
                        continue
                    targ_file = self.yaml_env_and_plugin_vars_populate(file_name)
                except IndexError:
                    targ_file = each_cmd.split('/')[-1]
                    self.logger.warning(
                        "\n\t[WARN] Missing filename to store data from %s." % each_cmd)
                    self.logger.warning("\t[WARN] Data will be stored in %s." % targ_file)

                targ_file_with_path = (self.ffdc_dir_path
                                       + self.ffdc_prefix
                                       + targ_file)

                # Creates a new file
                with open(targ_file_with_path, 'w') as fp:
                    if isinstance(result, dict):
                        fp.write(json.dumps(result))
                    else:
                        fp.write(result)
                    fp.close
                    executed_files_saved.append(targ_file)

            progress_counter += 1
            self.print_progress(progress_counter)

        self.logger.info("\n\t[Run] Commands execution completed.\t\t [OK]")

        for file in executed_files_saved:
            self.logger.info("\n\t\tSuccessfully save file " + file + ".")

    def collect_and_copy_ffdc(self,
                              ffdc_actions_for_target_type,
                              form_filename=False):
        r"""
        Send commands in ffdc_config file to targeted system.

        Description of argument(s):
        ffdc_actions_for_target_type     commands and files for the selected remote host type.
        form_filename                    if true, pre-pend self.target_type to filename
        """

        # Executing commands, if any
        self.ssh_execute_ffdc_commands(ffdc_actions_for_target_type,
                                       form_filename)

        # Copying files
        if self.ssh_remoteclient.scpclient:
            self.logger.info("\n\n\tCopying FFDC files from remote system %s.\n" % self.hostname)

            # Retrieving files from target system
            list_of_files = self.get_file_list(ffdc_actions_for_target_type)
            self.scp_ffdc(self.ffdc_dir_path, self.ffdc_prefix, form_filename, list_of_files)
        else:
            self.logger.info("\n\n\tSkip copying FFDC files from remote system %s.\n" % self.hostname)

    def get_command_list(self,
                         ffdc_actions_for_target_type):
        r"""
        Fetch list of commands from configuration file

        Description of argument(s):
        ffdc_actions_for_target_type    commands and files for the selected remote host type.
        """
        try:
            list_of_commands = ffdc_actions_for_target_type['COMMANDS']
        except KeyError:
            list_of_commands = []
        return list_of_commands

    def get_file_list(self,
                      ffdc_actions_for_target_type):
        r"""
        Fetch list of commands from configuration file

        Description of argument(s):
        ffdc_actions_for_target_type    commands and files for the selected remote host type.
        """
        try:
            list_of_files = ffdc_actions_for_target_type['FILES']
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
                                  ffdc_actions_for_target_type,
                                  form_filename=False):
        r"""
        Send commands in ffdc_config file to targeted system.

        Description of argument(s):
        ffdc_actions_for_target_type    commands and files for the selected remote host type.
        form_filename                    if true, pre-pend self.target_type to filename
        """
        self.logger.info("\n\t[Run] Executing commands on %s using %s"
                         % (self.hostname, ffdc_actions_for_target_type['PROTOCOL'][0]))

        list_of_commands = self.get_command_list(ffdc_actions_for_target_type)
        # If command list is empty, returns
        if not list_of_commands:
            return

        progress_counter = 0
        for command in list_of_commands:
            command_txt, command_timeout = self.unpack_command(command)

            if form_filename:
                command_txt = str(command_txt % self.target_type)

            cmd_exit_code, err, response = \
                self.ssh_remoteclient.execute_command(command_txt, command_timeout)

            if cmd_exit_code:
                self.logger.warning(
                    "\n\t\t[WARN] %s exits with code %s." % (command_txt, str(cmd_exit_code)))
                self.logger.warning("\t\t[WARN] %s " % err)

            progress_counter += 1
            self.print_progress(progress_counter)

        self.logger.info("\n\t[Run] Commands execution completed.\t\t [OK]")

    def group_copy(self,
                   ffdc_actions_for_target_type):
        r"""
        scp group of files (wild card) from remote host.

        Description of argument(s):
        fdc_actions_for_target_type    commands and files for the selected remote host type.
        """

        if self.ssh_remoteclient.scpclient:
            self.logger.info("\n\tCopying files from remote system %s via SCP.\n" % self.hostname)

            list_of_commands = self.get_command_list(ffdc_actions_for_target_type)
            # If command list is empty, returns
            if not list_of_commands:
                return

            for command in list_of_commands:
                try:
                    command = self.yaml_env_and_plugin_vars_populate(command)
                except IndexError:
                    self.logger.error("\t\tInvalid command %s" % command)
                    continue

                cmd_exit_code, err, response = \
                    self.ssh_remoteclient.execute_command(command)

                # If file does not exist, code take no action.
                # cmd_exit_code is ignored for this scenario.
                if response:
                    scp_result = \
                        self.ssh_remoteclient.scp_file_from_remote(response.split('\n'),
                                                                   self.ffdc_dir_path)
                    if scp_result:
                        self.logger.info("\t\tSuccessfully copied from " + self.hostname + ':' + command)
                else:
                    self.logger.info("\t\t%s has no result" % command)

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
                        '\tERROR: os.makedirs %s failed with PermissionError.\n' % dir_path)
                else:
                    self.logger.error(
                        '\tERROR: os.makedirs %s failed with %s.\n' % (dir_path, e.strerror))
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
        redfish_parm = 'redfishtool -r ' \
                       + self.hostname + ' -S Always raw GET /redfish/v1/'
        return(self.run_tool_cmd(redfish_parm, True))

    def verify_ipmi(self):
        r"""
        Verify remote host has IPMI LAN service active

        """
        if self.target_type == 'OPENBMC':
            ipmi_parm = 'ipmitool -I lanplus -C 17  -U ' + self.username + ' -P ' \
                + self.password + ' -H ' + self.hostname + ' power status'
        else:
            ipmi_parm = 'ipmitool -I lanplus  -P ' \
                + self.password + ' -H ' + self.hostname + ' power status'

        return(self.run_tool_cmd(ipmi_parm, True))

    def run_tool_cmd(self,
                     parms_string,
                     quiet=False):
        r"""
        Run CLI standard tool or scripts.

        Description of variable:
        parms_string         tool command options.
        quiet                do not print tool error message if True
        """

        result = subprocess.run([parms_string],
                                stdout=subprocess.PIPE,
                                stderr=subprocess.PIPE,
                                shell=True,
                                universal_newlines=True)

        if result.stderr and not quiet:
            self.logger.error('\n\t\tERROR with %s ' % parms_string)
            self.logger.error('\t\t' + result.stderr)

        return result.stdout

    def verify_protocol(self, protocol_list):
        r"""
        Perform protocol working check.

        Description of argument(s):
        protocol_list        List of protocol.
        """

        tmp_list = []
        if self.target_is_pingable():
            tmp_list.append("SHELL")

        for protocol in protocol_list:
            if self.remote_protocol != 'ALL':
                if self.remote_protocol != protocol:
                    continue

            # Only check SSH/SCP once for both protocols
            if protocol == 'SSH' or protocol == 'SCP' and protocol not in tmp_list:
                if self.ssh_to_target_system():
                    # Add only what user asked.
                    if self.remote_protocol != 'ALL':
                        tmp_list.append(self.remote_protocol)
                    else:
                        tmp_list.append('SSH')
                        tmp_list.append('SCP')

            if protocol == 'TELNET':
                if self.telnet_to_target_system():
                    tmp_list.append(protocol)

            if protocol == 'REDFISH':
                if self.verify_redfish():
                    tmp_list.append(protocol)
                    self.logger.info("\n\t[Check] %s Redfish Service.\t\t [OK]" % self.hostname)
                else:
                    self.logger.info("\n\t[Check] %s Redfish Service.\t\t [NOT AVAILABLE]" % self.hostname)

            if protocol == 'IPMI':
                if self.verify_ipmi():
                    tmp_list.append(protocol)
                    self.logger.info("\n\t[Check] %s IPMI LAN Service.\t\t [OK]" % self.hostname)
                else:
                    self.logger.info("\n\t[Check] %s IPMI LAN Service.\t\t [NOT AVAILABLE]" % self.hostname)

        return tmp_list

    def load_env(self):
        r"""
        Perform protocol working check.

        """
        # This is for the env vars a user can use in YAML to load it at runtime.
        # Example YAML:
        # -COMMANDS:
        #    - my_command ${hostname}  ${username}   ${password}
        os.environ['hostname'] = self.hostname
        os.environ['username'] = self.username
        os.environ['password'] = self.password

        # Append default Env.
        self.env_dict['hostname'] = self.hostname
        self.env_dict['username'] = self.username
        self.env_dict['password'] = self.password

        try:
            tmp_env_dict = {}
            if self.env_vars:
                tmp_env_dict = json.loads(self.env_vars)
                # Export ENV vars default.
                for key, value in tmp_env_dict.items():
                    os.environ[key] = value
                    self.env_dict[key] = str(value)

            if self.econfig:
                with open(self.econfig, 'r') as file:
                    try:
                        tmp_env_dict = yaml.load(file, Loader=yaml.FullLoader)
                    except yaml.YAMLError as e:
                        self.logger.error(e)
                        sys.exit(-1)
                # Export ENV vars.
                for key, value in tmp_env_dict['env_params'].items():
                    os.environ[key] = str(value)
                    self.env_dict[key] = str(value)
        except json.decoder.JSONDecodeError as e:
            self.logger.error("\n\tERROR: %s " % e)
            sys.exit(-1)

        # This to mask the password from displaying on the console.
        mask_dict = self.env_dict.copy()
        for k, v in mask_dict.items():
            if k.lower().find("password") != -1:
                hidden_text = []
                hidden_text.append(v)
                password_regex = '(' +\
                    '|'.join([re.escape(x) for x in hidden_text]) + ')'
                mask_dict[k] = re.sub(password_regex, "********", v)

        self.logger.info(json.dumps(mask_dict, indent=8, sort_keys=False))

    def execute_python_eval(self, eval_string):
        r"""
        Execute qualified python function string using eval.

        Description of argument(s):
        eval_string        Execute the python object.

        Example:
                eval(plugin.foo_func.foo_func(10))
        """
        try:
            self.logger.info("\tExecuting plugin func()")
            self.logger.debug("\tCall func: %s" % eval_string)
            result = eval(eval_string)
            self.logger.info("\treturn: %s" % str(result))
        except (ValueError,
                SyntaxError,
                NameError,
                AttributeError,
                TypeError) as e:
            self.logger.error("\tERROR: execute_python_eval: %s" % e)
            # Set the plugin error state.
            plugin_error_dict['exit_on_error'] = True
            self.logger.info("\treturn: PLUGIN_EVAL_ERROR")
            return 'PLUGIN_EVAL_ERROR'

        return result

    def execute_plugin_block(self, plugin_cmd_list):
        r"""
        Pack the plugin command to quailifed python string object.

        Description of argument(s):
        plugin_list_dict      Plugin block read from YAML
                              [{'plugin_name': 'plugin.foo_func.my_func'},
                               {'plugin_args': [10]}]

        Example:
            - plugin:
              - plugin_name: plugin.foo_func.my_func
              - plugin_args:
                - arg1
                - arg2

            - plugin:
              - plugin_name: result = plugin.foo_func.my_func
              - plugin_args:
                - arg1
                - arg2

            - plugin:
              - plugin_name: result1,result2 = plugin.foo_func.my_func
              - plugin_args:
                - arg1
                - arg2
        """
        try:
            idx = self.key_index_list_dict('plugin_name', plugin_cmd_list)
            plugin_name = plugin_cmd_list[idx]['plugin_name']
            # Equal separator means plugin function returns result.
            if ' = ' in plugin_name:
                # Ex. ['result', 'plugin.foo_func.my_func']
                plugin_name_args = plugin_name.split(' = ')
                # plugin func return data.
                for arg in plugin_name_args:
                    if arg == plugin_name_args[-1]:
                        plugin_name = arg
                    else:
                        plugin_resp = arg.split(',')
                        # ['result1','result2']
                        for x in plugin_resp:
                            global_plugin_list.append(x)
                            global_plugin_dict[x] = ""

            # Walk the plugin args ['arg1,'arg2']
            # If the YAML plugin statement 'plugin_args' is not declared.
            if any('plugin_args' in d for d in plugin_cmd_list):
                idx = self.key_index_list_dict('plugin_args', plugin_cmd_list)
                plugin_args = plugin_cmd_list[idx]['plugin_args']
                if plugin_args:
                    plugin_args = self.yaml_args_populate(plugin_args)
                else:
                    plugin_args = []
            else:
                plugin_args = self.yaml_args_populate([])

            # Pack the args arg1, arg2, .... argn into
            # "arg1","arg2","argn"  string as params for function.
            parm_args_str = self.yaml_args_string(plugin_args)
            if parm_args_str:
                plugin_func = plugin_name + '(' + parm_args_str + ')'
            else:
                plugin_func = plugin_name + '()'

            # Execute plugin function.
            if global_plugin_dict:
                resp = self.execute_python_eval(plugin_func)
                # Update plugin vars dict if there is any.
                if resp != 'PLUGIN_EVAL_ERROR':
                    self.response_args_data(resp)
            else:
                resp = self.execute_python_eval(plugin_func)
        except Exception as e:
            # Set the plugin error state.
            plugin_error_dict['exit_on_error'] = True
            self.logger.error("\tERROR: execute_plugin_block: %s" % e)
            pass

        # There is a real error executing the plugin function.
        if resp == 'PLUGIN_EVAL_ERROR':
            return resp

        # Check if plugin_expects_return (int, string, list,dict etc)
        if any('plugin_expects_return' in d for d in plugin_cmd_list):
            idx = self.key_index_list_dict('plugin_expects_return', plugin_cmd_list)
            plugin_expects = plugin_cmd_list[idx]['plugin_expects_return']
            if plugin_expects:
                if resp:
                    if self.plugin_expect_type(plugin_expects, resp) == 'INVALID':
                        self.logger.error("\tWARN: Plugin error check skipped")
                    elif not self.plugin_expect_type(plugin_expects, resp):
                        self.logger.error("\tERROR: Plugin expects return data: %s"
                                          % plugin_expects)
                        plugin_error_dict['exit_on_error'] = True
                elif not resp:
                    self.logger.error("\tERROR: Plugin func failed to return data")
                    plugin_error_dict['exit_on_error'] = True

        return resp

    def response_args_data(self, plugin_resp):
        r"""
        Parse the plugin function response and update plugin return variable.

        plugin_resp       Response data from plugin function.
        """
        resp_list = []
        resp_data = ""

        # There is nothing to update the plugin response.
        if len(global_plugin_list) == 0 or plugin_resp == 'None':
            return

        if isinstance(plugin_resp, str):
            resp_data = plugin_resp.strip('\r\n\t')
            resp_list.append(resp_data)
        elif isinstance(plugin_resp, bytes):
            resp_data = str(plugin_resp, 'UTF-8').strip('\r\n\t')
            resp_list.append(resp_data)
        elif isinstance(plugin_resp, tuple):
            if len(global_plugin_list) == 1:
                resp_list.append(plugin_resp)
            else:
                resp_list = list(plugin_resp)
                resp_list = [x.strip('\r\n\t') for x in resp_list]
        elif isinstance(plugin_resp, list):
            if len(global_plugin_list) == 1:
                resp_list.append([x.strip('\r\n\t') for x in plugin_resp])
            else:
                resp_list = [x.strip('\r\n\t') for x in plugin_resp]
        elif isinstance(plugin_resp, int) or isinstance(plugin_resp, float):
            resp_list.append(plugin_resp)

        # Iterate if there is a list of plugin return vars to update.
        for idx, item in enumerate(resp_list, start=0):
            # Exit loop, done required loop.
            if idx >= len(global_plugin_list):
                break
            # Find the index of the return func in the list and
            # update the global func return dictionary.
            try:
                dict_idx = global_plugin_list[idx]
                global_plugin_dict[dict_idx] = item
            except (IndexError, ValueError) as e:
                self.logger.warn("\tWARN: response_args_data: %s" % e)
                pass

        # Done updating plugin dict irrespective of pass or failed,
        # clear all the list element for next plugin block execute.
        global_plugin_list.clear()

    def yaml_args_string(self, plugin_args):
        r"""
        Pack the args into string.

        plugin_args            arg list ['arg1','arg2,'argn']
        """
        args_str = ''
        for args in plugin_args:
            if args:
                if isinstance(args, (int, float)):
                    args_str += str(args)
                elif args in global_plugin_type_list:
                    args_str += str(global_plugin_dict[args])
                else:
                    args_str += '"' + str(args.strip('\r\n\t')) + '"'
            # Skip last list element.
            if args != plugin_args[-1]:
                args_str += ","
        return args_str

    def yaml_args_populate(self, yaml_arg_list):
        r"""
        Decode env and plugin vars and populate.

        Description of argument(s):
        yaml_arg_list         arg list read from YAML

        Example:
          - plugin_args:
            - arg1
            - arg2

                  yaml_arg_list:  [arg2, arg2]
        """
        # Get the env loaded keys as list ['hostname', 'username', 'password'].
        env_vars_list = list(self.env_dict)

        if isinstance(yaml_arg_list, list):
            tmp_list = []
            for arg in yaml_arg_list:
                if isinstance(arg, (int, float)):
                    tmp_list.append(arg)
                    continue
                elif isinstance(arg, str):
                    arg_str = self.yaml_env_and_plugin_vars_populate(str(arg))
                    tmp_list.append(arg_str)
                else:
                    tmp_list.append(arg)

            # return populated list.
            return tmp_list

    def yaml_env_and_plugin_vars_populate(self, yaml_arg_str):
        r"""
        Update ${MY_VAR} and plugin vars.

        Description of argument(s):
        yaml_arg_str         arg string read from YAML.

        Example:
            - cat ${MY_VAR}
            - ls -AX my_plugin_var
        """
        # Parse the string for env vars ${env_vars}.
        try:
            # Example, list of matching env vars ['username', 'password', 'hostname']
            # Extra escape \ for special symbols. '\$\{([^\}]+)\}' works good.
            var_name_regex = '\\$\\{([^\\}]+)\\}'
            env_var_names_list = re.findall(var_name_regex, yaml_arg_str)
            for var in env_var_names_list:
                env_var = os.environ[var]
                env_replace = '${' + var + '}'
                yaml_arg_str = yaml_arg_str.replace(env_replace, env_var)
        except Exception as e:
            self.logger.error("\tERROR:yaml_env_vars_populate: %s" % e)
            pass

        # Parse the string for plugin vars.
        try:
            # Example, list of plugin vars ['my_username', 'my_data']
            plugin_var_name_list = global_plugin_dict.keys()
            for var in plugin_var_name_list:
                # skip env var list already populated above code block list.
                if var in env_var_names_list:
                    continue
                # If this plugin var exist but empty in dict, don't replace.
                # This is either a YAML plugin statement incorrectly used or
                # user added a plugin var which is not going to be populated.
                if yaml_arg_str in global_plugin_dict:
                    if isinstance(global_plugin_dict[var], (list, dict)):
                        # List data type or dict can't be replaced, use directly
                        # in eval function call.
                        global_plugin_type_list.append(var)
                    else:
                        yaml_arg_str = yaml_arg_str.replace(str(var), str(global_plugin_dict[var]))
                # Just a string like filename or command.
                else:
                    yaml_arg_str = yaml_arg_str.replace(str(var), str(global_plugin_dict[var]))
        except (IndexError, ValueError) as e:
            self.logger.error("\tERROR: yaml_plugin_vars_populate: %s" % e)
            pass

        return yaml_arg_str

    def plugin_error_check(self, plugin_dict):
        r"""
        Plugin error dict processing.

        Description of argument(s):
        plugin_dict        Dictionary of plugin error.
        """
        if any('plugin_error' in d for d in plugin_dict):
            for d in plugin_dict:
                if 'plugin_error' in d:
                    value = d['plugin_error']
                    # Reference if the error is set or not by plugin.
                    return plugin_error_dict[value]

    def key_index_list_dict(self, key, list_dict):
        r"""
        Iterate list of dictionary and return index if the key match is found.

        Description of argument(s):
        key           Valid Key in a dict.
        list_dict     list of dictionary.
        """
        for i, d in enumerate(list_dict):
            if key in d.keys():
                return i

    def plugin_expect_type(self, type, data):
        r"""
        Plugin expect directive type check.
        """
        if type == 'int':
            return isinstance(data, int)
        elif type == 'float':
            return isinstance(data, float)
        elif type == 'str':
            return isinstance(data, str)
        elif type == 'list':
            return isinstance(data, list)
        elif type == 'dict':
            return isinstance(data, dict)
        elif type == 'tuple':
            return isinstance(data, tuple)
        else:
            self.logger.info("\tInvalid data type requested: %s" % type)
            return 'INVALID'
