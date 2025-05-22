#!/usr/bin/env python3

r"""
See class prolog below for details.
"""

import importlib
import json
import logging
import os
import platform
import re
import subprocess
import sys
import time
from errno import EACCES, EPERM
from typing import Any

import yaml

sys.dont_write_bytecode = True


script_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.append(script_dir)
# Walk path and append to sys.path
for root, dirs, files in os.walk(script_dir):
    for dir in dirs:
        sys.path.append(os.path.join(root, dir))

from ssh_utility import SSHRemoteclient  # NOQA
from telnet_utility import TelnetRemoteclient  # NOQA

r"""
This is for plugin functions returning data or responses to the caller
in YAML plugin setup.

Example:

    - plugin:
      - plugin_name: plugin.ssh_execution
      - plugin_function: version = ssh_execute_cmd
      - plugin_args:
        - ${hostname}
        - ${username}
        - ${password}
        - "cat /etc/os-release | grep VERSION_ID | awk -F'=' '{print $2}'"
     - plugin:
        - plugin_name: plugin.print_vars
        - plugin_function: print_vars
        - plugin_args:
          - version

where first plugin "version" var is used by another plugin in the YAML
block or plugin

"""
# Global variables for storing plugin return values, plugin return variables,
# and log storage path.
global global_log_store_path
global global_plugin_dict
global global_plugin_list
global global_plugin_type_list
global global_plugin_error_dict

# Hold the plugin return values in a dictionary and plugin return variables in
# a list. The dictionary is used for referencing and updating variables during
# parsing in the parser, while the list is used for storing current variables
# from the plugin block that need processing.
global_plugin_dict = {}
global_plugin_list = []

# Hold the plugin return named variables if the function returned values are
# lists or dictionaries. This list is used to reference the plugin dictionary
# for python function execute arguments.
# Example: ['version']
global_plugin_type_list = []

# Path where logs are to be stored or written.
global_log_store_path = ""

# Plugin error state defaults.
global_plugin_error_dict = {
    "exit_on_error": False,
    "continue_on_error": False,
}


def execute_python_function(module_name, function_name, *args, **kwargs):
    r"""
    Execute a Python function from a module dynamically.

    This function dynamically imports a module and executes a specified
    function from that module with the provided arguments. The function takes
    the module name, function name, and arguments as input. The function
    returns the result of the executed function.

    If an ImportError or AttributeError occurs, the function prints an error
    message and returns None.

    Parameters:
        module_name (str):   The name of the module containing the function.
        function_name (str): The name of the function to execute.
        *args:               Positional arguments to pass to the function.
        **kwargs:            Keyword arguments to pass to the function.

    Returns:
        Any: The result of the executed function or None if an error occurs.
    """
    try:
        # Dynamically import the module.
        module = importlib.import_module(module_name)

        # Get the function from the module.
        func = getattr(module, function_name)

        # Call the function with the provided arguments.
        result = func(*args, **kwargs)

    except (ImportError, AttributeError) as e:
        print(f"\tERROR: execute_python_function: {e}")
        # Set the plugin error state.
        global_plugin_error_dict["exit_on_error"] = True
        print("\treturn: PLUGIN_EXEC_ERROR")
        return "PLUGIN_EXEC_ERROR"

    return result


class ffdc_collector:
    r"""
    Execute commands from a configuration file to collect log files and store
    the generated files at the specified location.

    This class is designed to execute commands specified in a configuration
    YAML file to collect log files from a remote host.

    The class establishes connections using SSH, Telnet, or other protocols
    based on the configuration. It fetches and stores the generated files at
    the specified location. The class provides methods for initializing the
    collector, executing commands, and handling errors.
    """

    def __init__(
        self,
        hostname,
        username,
        password,
        port_ssh,
        port_https,
        port_ipmi,
        ffdc_config,
        location,
        remote_type,
        remote_protocol,
        env_vars,
        econfig,
        log_level,
    ):
        r"""
        Initialize the FFDCCollector object with the provided parameters.

        This method initializes an FFDCCollector object with the given
        attributes. The attributes represent the configuration for connecting
        to a remote system, collecting log data, and storing the collected
        data.

        Parameters:
            hostname (str):             Name or IP address of the targeted
                                        (remote) system.
            username (str):             User on the targeted system with access
                                        to log files.
            password (str):             Password for the user on the targeted
                                        system.
            port_ssh (int, optional):   SSH port value. Defaults to 22.
            port_https (int, optional): HTTPS port value. Defaults to 443.
            port_ipmi (int, optional):  IPMI port value. Defaults to 623.
            ffdc_config (str):          Configuration file listing commands
                                        and files for FFDC.
            location (str):             Where to store collected log data.
            remote_type (str):          Block YAML type name of the remote
                                        host.
            remote_protocol (str):      Protocol to use to collect data.
            env_vars (dict, optional):  User-defined CLI environment variables.
                                        Defaults to None.
            econfig (str, optional):    User-defined environment variables
                                        YAML file. Defaults to None.
            log_level (str, optional):  Log level for the collector.
                                        Defaults to "INFO".
        """

        self.hostname = hostname
        self.username = username
        self.password = password
        self.port_ssh = str(port_ssh)
        self.port_https = str(port_https)
        self.port_ipmi = str(port_ipmi)
        self.ffdc_config = ffdc_config
        self.location = location + "/" + remote_type.upper()
        self.ssh_remoteclient = None
        self.telnet_remoteclient = None
        self.ffdc_dir_path = ""
        self.ffdc_prefix = ""
        self.target_type = remote_type.upper()
        self.remote_protocol = remote_protocol.upper()
        self.env_vars = env_vars if env_vars else {}
        self.econfig = econfig if econfig else {}
        self.start_time = 0
        self.elapsed_time = ""
        self.env_dict = {}
        self.logger = None

        """
        Set prefix values for SCP files and directories.
        Since the time stamp is at second granularity, these values are set
        here to be sure that all files for this run will have the same
        timestamps and be saved in the same directory.
        self.location == local system for now
        """
        self.set_ffdc_default_store_path()

        # Logger for this run.  Need to be after set_ffdc_default_store_path()
        self.script_logging(getattr(logging, log_level.upper()))

        # Verify top level directory exists for storage
        self.validate_local_store(self.location)

        if self.verify_script_env():
            try:
                with open(self.ffdc_config, "r") as file:
                    self.ffdc_actions = yaml.safe_load(file)
            except yaml.YAMLError as e:
                self.logger.error(e)
                sys.exit(-1)

            if self.target_type not in self.ffdc_actions:
                self.logger.error(
                    "\n\tERROR: %s is not listed in %s.\n\n"
                    % (self.target_type, self.ffdc_config)
                )
                sys.exit(-1)

            self.logger.info("\n\tENV: User define input YAML variables")
            self.load_env()
        else:
            sys.exit(-1)

    def verify_script_env(self):
        r"""
        Verify that all required environment variables are set.

        This method checks if all required environment variables are set.
        If any required variable is missing, the method returns False.
        Otherwise, it returns True.

        Returns:
            bool: True if all required environment variables are set,
            False otherwise.
        """
        # Import to log version
        import click
        import paramiko

        run_env_ok = True

        try:
            redfishtool_version = (
                self.run_tool_cmd("redfishtool -V").split(" ")[2].strip("\n")
            )
        except Exception as e:
            self.logger.error("\tEXCEPTION redfishtool: %s", e)
            redfishtool_version = "Not Installed (optional)"

        try:
            ipmitool_version = self.run_tool_cmd("ipmitool -V").split(" ")[2]
        except Exception as e:
            self.logger.error("\tEXCEPTION ipmitool: %s", e)
            ipmitool_version = "Not Installed (optional)"

        self.logger.info("\n\t---- Script host environment ----")
        self.logger.info(
            "\t{:<10}  {:<10}".format("Script hostname", os.uname()[1])
        )
        self.logger.info(
            "\t{:<10}  {:<10}".format("Script host os", platform.platform())
        )
        self.logger.info(
            "\t{:<10}  {:>10}".format("Python", platform.python_version())
        )
        self.logger.info("\t{:<10}  {:>10}".format("PyYAML", yaml.__version__))
        self.logger.info("\t{:<10}  {:>10}".format("click", click.__version__))
        self.logger.info(
            "\t{:<10}  {:>10}".format("paramiko", paramiko.__version__)
        )
        self.logger.info(
            "\t{:<10}  {:>9}".format("redfishtool", redfishtool_version)
        )
        self.logger.info(
            "\t{:<10}  {:>12}".format("ipmitool", ipmitool_version)
        )

        if eval(yaml.__version__.replace(".", ",")) < (5, 3, 0):
            self.logger.error(
                "\n\tERROR: Python or python packages do not meet minimum"
                " version requirement."
            )
            self.logger.error(
                "\tERROR: PyYAML version 5.3.0 or higher is needed.\n"
            )
            run_env_ok = False

        self.logger.info("\t---- End script host environment ----")
        return run_env_ok

    def script_logging(self, log_level_attr):
        """
        Create a logger for the script with the specified log level.

        This method creates a logger for the script with the specified
        log level. The logger is configured to write log messages to a file
        and the console.

        self.logger = logging.getLogger(__name__)

        Setting logger with __name__ will add the trace
        Example:

            INFO:ffdc_collector:    System Type: OPENBMC

        Currently, set to empty purposely to log as
            System Type: OPENBMC

        Parameters:
            log_level_attr (str):   The log level for the logger
                                    (e.g., "DEBUG", "INFO", "WARNING",
                                    "ERROR", "CRITICAL").

        Returns:
            None
        """
        self.logger = logging.getLogger()
        self.logger.setLevel(log_level_attr)

        log_file_handler = logging.FileHandler(
            self.ffdc_dir_path + "collector.log"
        )
        stdout_handler = logging.StreamHandler(sys.stdout)

        self.logger.addHandler(log_file_handler)
        self.logger.addHandler(stdout_handler)

        # Turn off paramiko INFO logging
        logging.getLogger("paramiko").setLevel(logging.WARNING)

    def target_is_pingable(self):
        r"""
        Check if the target system is ping-able.

        This method checks if the target system is reachable by sending an
        ICMP echo request (ping). If the target system responds to the ping,
        the method returns True. Otherwise, it returns False.

        Returns:
            bool: True if the target system is ping-able, False otherwise.
        """
        response = os.system("ping -c 2 %s  2>&1 >/dev/null" % self.hostname)
        if response == 0:
            self.logger.info(
                "\n\t[Check] %s is ping-able.\t\t [OK]" % self.hostname
            )
            return True
        else:
            self.logger.error(
                "\n\tERROR: %s is not ping-able. FFDC collection aborted.\n"
                % self.hostname
            )
            sys.exit(-1)
        return False

    def collect_ffdc(self):
        r"""
        Initiate FFDC collection based on the requested protocol.

        This method initiates FFDC (First Failure Data Capture) collection
        based on the requested protocol (SSH,SCP, TELNET, REDFISH, IPMI).
        The method establishes a connection to the target system using the
        specified protocol and collects the required FFDC data.

        Returns:
            None
        """
        self.logger.info(
            "\n\t---- Start communicating with %s ----" % self.hostname
        )
        self.start_time = time.time()

        # Find the list of target and protocol supported.
        check_protocol_list = []
        config_dict = self.ffdc_actions

        for target_type in config_dict.keys():
            if self.target_type != target_type:
                continue

            for k, v in config_dict[target_type].items():
                if v["PROTOCOL"][0] not in check_protocol_list:
                    check_protocol_list.append(v["PROTOCOL"][0])

        self.logger.info(
            "\n\t %s protocol type: %s"
            % (self.target_type, check_protocol_list)
        )

        verified_working_protocol = self.verify_protocol(check_protocol_list)

        if verified_working_protocol:
            self.logger.info(
                "\n\t---- Completed protocol pre-requisite check ----\n"
            )

        # Verify top level directory exists for storage
        self.validate_local_store(self.location)

        if (self.remote_protocol not in verified_working_protocol) and (
            self.remote_protocol != "ALL"
        ):
            self.logger.info(
                "\n\tWorking protocol list: %s" % verified_working_protocol
            )
            self.logger.error(
                "\tERROR: Requested protocol %s is not in working protocol"
                " list.\n" % self.remote_protocol
            )
            sys.exit(-1)
        else:
            self.generate_ffdc(verified_working_protocol)

    def ssh_to_target_system(self):
        r"""
        Establish an SSH connection to the target system.

        This method establishes an SSH connection to the target system using
        the provided hostname, username, password, and SSH port. If the
        connection is successful, the method returns True. Otherwise, it logs
        an error message and returns False.

        Returns:
            bool: True if the connection is successful, False otherwise.
        """

        self.ssh_remoteclient = SSHRemoteclient(
            self.hostname, self.username, self.password, self.port_ssh
        )

        if self.ssh_remoteclient.ssh_remoteclient_login():
            self.logger.info(
                "\n\t[Check] %s SSH connection established.\t [OK]"
                % self.hostname
            )

            # Check scp connection.
            # If scp connection fails,
            # continue with FFDC generation but skip scp files to local host.
            self.ssh_remoteclient.scp_connection()
            return True
        else:
            self.logger.info(
                "\n\t[Check] %s SSH connection.\t [NOT AVAILABLE]"
                % self.hostname
            )
            return False

    def telnet_to_target_system(self):
        r"""
        Establish a Telnet connection to the target system.

        This method establishes a Telnet connection to the target system using
        the provided hostname, username, and Telnet port. If the connection is
        successful, the method returns True. Otherwise, it logs an error
        message and returns False.

        Returns:
            bool: True if the connection is successful, False otherwise.
        """
        self.telnet_remoteclient = TelnetRemoteclient(
            self.hostname, self.username, self.password
        )
        if self.telnet_remoteclient.tn_remoteclient_login():
            self.logger.info(
                "\n\t[Check] %s Telnet connection established.\t [OK]"
                % self.hostname
            )
            return True
        else:
            self.logger.info(
                "\n\t[Check] %s Telnet connection.\t [NOT AVAILABLE]"
                % self.hostname
            )
            return False

    def generate_ffdc(self, working_protocol_list):
        r"""
        Generate FFDC (First Failure Data Capture) based on the remote host
        type and working protocols.

        This method determines the actions to be performed for generating FFDC
        based on the remote host type and the list of confirmed working
        protocols. The method iterates through the available actions for the
        remote host type and checks if any of the working protocols are
        supported. If a supported protocol is found, the method executes the
        corresponding FFDC generation action.

        Parameters:
            working_protocol_list (list):  A list of confirmed working
                                           protocols to connect to the
                                           remote host.

        Returns:
            None
        """
        self.logger.info(
            "\n\t---- Executing commands on " + self.hostname + " ----"
        )
        self.logger.info(
            "\n\tWorking protocol list: %s" % working_protocol_list
        )

        config_dict = self.ffdc_actions
        for target_type in config_dict.keys():
            if self.target_type != target_type:
                continue

            self.logger.info("\n\tFFDC Path: %s " % self.ffdc_dir_path)
            global_plugin_dict["global_log_store_path"] = self.ffdc_dir_path
            self.logger.info("\tSystem Type: %s" % target_type)
            for k, v in config_dict[target_type].items():
                protocol = v["PROTOCOL"][0]

                if (
                    self.remote_protocol not in working_protocol_list
                    and self.remote_protocol != "ALL"
                ) or protocol not in working_protocol_list:
                    continue

                if protocol in working_protocol_list:
                    if protocol in ["SSH", "SCP"]:
                        self.protocol_ssh(protocol, target_type, k)
                    elif protocol == "TELNET":
                        self.protocol_telnet(target_type, k)
                    elif protocol in ["REDFISH", "IPMI", "SHELL"]:
                        self.protocol_service_execute(protocol, target_type, k)
                else:
                    self.logger.error(
                        "\n\tERROR: %s is not available for %s."
                        % (protocol, self.hostname)
                    )

        # Close network connection after collecting all files
        self.elapsed_time = time.strftime(
            "%H:%M:%S", time.gmtime(time.time() - self.start_time)
        )
        self.logger.info("\n\tTotal time taken: %s" % self.elapsed_time)
        if self.ssh_remoteclient:
            self.ssh_remoteclient.ssh_remoteclient_disconnect()
        if self.telnet_remoteclient:
            self.telnet_remoteclient.tn_remoteclient_disconnect()

    def protocol_ssh(self, protocol, target_type, sub_type):
        r"""
        Perform actions using SSH and SCP protocols.

        This method executes a set of commands using the SSH protocol to
        connect to the target system and collect FFDC data. The method takes
        the protocol, target type, and sub-type as arguments and performs the
        corresponding actions based on the provided parameters.

        Parameters:
            protocol (str):    The protocol to execute (SSH or SCP).
            target_type (str): The type group of the remote host.
            sub_type (str):    The group type of commands to execute.

        Returns:
            None
        """
        if protocol == "SCP":
            self.group_copy(self.ffdc_actions[target_type][sub_type])
        else:
            self.collect_and_copy_ffdc(
                self.ffdc_actions[target_type][sub_type]
            )

    def protocol_telnet(self, target_type, sub_type):
        r"""
        Perform actions using the Telnet protocol.

        This method executes a set of commands using the Telnet protocol to
        connect to the target system and collect FFDC data. The method takes
        the target type and sub-type as arguments and performs the
        corresponding actions based on the provided parameters.

        Parameters:
            target_type (str): The type group of the remote host.
            sub_type (str):    The group type of commands to execute.

        Returns:
            None
        """
        self.logger.info(
            "\n\t[Run] Executing commands on %s using %s"
            % (self.hostname, "TELNET")
        )
        telnet_files_saved = []
        progress_counter = 0
        list_of_commands = self.ffdc_actions[target_type][sub_type]["COMMANDS"]
        for index, each_cmd in enumerate(list_of_commands, start=0):
            command_txt, command_timeout = self.unpack_command(each_cmd)
            result = self.telnet_remoteclient.execute_command(
                command_txt, command_timeout
            )
            if result:
                try:
                    targ_file = self.ffdc_actions[target_type][sub_type][
                        "FILES"
                    ][index]
                except IndexError:
                    targ_file = command_txt
                    self.logger.warning(
                        "\n\t[WARN] Missing filename to store data from"
                        " telnet %s." % each_cmd
                    )
                    self.logger.warning(
                        "\t[WARN] Data will be stored in %s." % targ_file
                    )
                targ_file_with_path = (
                    self.ffdc_dir_path + self.ffdc_prefix + targ_file
                )
                # Creates a new file
                with open(targ_file_with_path, "w") as fp:
                    fp.write(result)
                    fp.close
                    telnet_files_saved.append(targ_file)
            progress_counter += 1
            self.print_progress(progress_counter)
        self.logger.info("\n\t[Run] Commands execution completed.\t\t [OK]")
        for file in telnet_files_saved:
            self.logger.info("\n\t\tSuccessfully save file " + file + ".")

    def protocol_service_execute(self, protocol, target_type, sub_type):
        r"""
        Perform actions for a given protocol.

        This method executes a set of commands using the specified protocol to
        connect to the target system and collect FFDC data. The method takes
        the protocol, target type, and sub-type as arguments and performs the
        corresponding actions based on the provided parameters.

        Parameters:
            protocol (str):    The protocol to execute
                               (REDFISH, IPMI, or SHELL).
            target_type (str): The type group of the remote host.
            sub_type (str):    The group type of commands to execute.

        Returns:
            None
        """
        self.logger.info(
            "\n\t[Run] Executing commands to %s using %s"
            % (self.hostname, protocol)
        )
        executed_files_saved = []
        progress_counter = 0
        list_of_cmd = self.get_command_list(
            self.ffdc_actions[target_type][sub_type]
        )
        for index, each_cmd in enumerate(list_of_cmd, start=0):
            plugin_call = False
            if isinstance(each_cmd, dict):
                if "plugin" in each_cmd:
                    # If the error is set and plugin explicitly
                    # requested to skip execution on error..
                    if global_plugin_error_dict[
                        "exit_on_error"
                    ] and self.plugin_error_check(each_cmd["plugin"]):
                        self.logger.info(
                            "\n\t[PLUGIN-ERROR] exit_on_error: %s"
                            % global_plugin_error_dict["exit_on_error"]
                        )
                        self.logger.info(
                            "\t[PLUGIN-SKIP] %s" % each_cmd["plugin"][0]
                        )
                        continue
                    plugin_call = True
                    # call the plugin
                    self.logger.info("\n\t[PLUGIN-START]")
                    result = self.execute_plugin_block(each_cmd["plugin"])
                    self.logger.info("\t[PLUGIN-END]\n")
            else:
                each_cmd = self.yaml_env_and_plugin_vars_populate(each_cmd)

            if not plugin_call:
                result = self.run_tool_cmd(each_cmd)
            if result:
                try:
                    file_name = self.get_file_list(
                        self.ffdc_actions[target_type][sub_type]
                    )[index]
                    # If file is specified as None.
                    if file_name == "None":
                        continue
                    targ_file = self.yaml_env_and_plugin_vars_populate(
                        file_name
                    )
                except IndexError:
                    targ_file = each_cmd.split("/")[-1]
                    self.logger.warning(
                        "\n\t[WARN] Missing filename to store data from %s."
                        % each_cmd
                    )
                    self.logger.warning(
                        "\t[WARN] Data will be stored in %s." % targ_file
                    )

                targ_file_with_path = (
                    self.ffdc_dir_path + self.ffdc_prefix + targ_file
                )

                # Creates a new file
                with open(targ_file_with_path, "w") as fp:
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

    def collect_and_copy_ffdc(
        self, ffdc_actions_for_target_type, form_filename=False
    ):
        r"""
        Send commands and collect FFDC data from the targeted system.

        This method sends a set of commands and collects FFDC data from the
        targeted system based on the provided ffdc_actions_for_target_type
        dictionary. The method also has an optional form_filename parameter,
        which, if set to True, prepends the target type to the output file
        name.

        Parameters:
            ffdc_actions_for_target_type (dict): A dictionary containing
                                                 commands and files for the
                                                 selected remote host type.
            form_filename (bool, optional):      If True, prepends the target
                                                 type to the output file name.
                                                 Defaults to False.

        Returns:
            None
        """
        # Executing commands, if any
        self.ssh_execute_ffdc_commands(
            ffdc_actions_for_target_type, form_filename
        )

        # Copying files
        if self.ssh_remoteclient.scpclient:
            self.logger.info(
                "\n\n\tCopying FFDC files from remote system %s.\n"
                % self.hostname
            )

            # Retrieving files from target system
            list_of_files = self.get_file_list(ffdc_actions_for_target_type)
            self.scp_ffdc(
                self.ffdc_dir_path,
                self.ffdc_prefix,
                form_filename,
                list_of_files,
            )
        else:
            self.logger.info(
                "\n\n\tSkip copying FFDC files from remote system %s.\n"
                % self.hostname
            )

    def get_command_list(self, ffdc_actions_for_target_type):
        r"""
        Fetch a list of commands from the configuration file.

        This method retrieves a list of commands from the
        ffdc_actions_for_target_type dictionary, which contains commands and
        files for the selected remote host type. The method returns the list
        of commands.

        Parameters:
            ffdc_actions_for_target_type (dict): A dictionary containing
                                                 commands and files for the
                                                 selected remote host type.

        Returns:
            list: A list of commands.
        """
        try:
            list_of_commands = ffdc_actions_for_target_type["COMMANDS"]
            # Update any global reserved variable name with value in dict.
            list_of_commands = self.update_vars_with_env_values(
                global_plugin_dict, list_of_commands
            )
        except KeyError:
            list_of_commands = []
        return list_of_commands

    def get_file_list(self, ffdc_actions_for_target_type):
        r"""
        Fetch a list of files from the configuration file.

        This method retrieves a list of files from the
        ffdc_actions_for_target_type dictionary, which contains commands and
        files for the selected remote host type. The method returns the list
        of files.

        Parameters:
            ffdc_actions_for_target_type (dict): A dictionary containing
                                                 commands and files for the
                                                 selected remote host type.

        Returns:
            list: A list of files.
        """
        try:
            list_of_files = ffdc_actions_for_target_type["FILES"]
        except KeyError:
            list_of_files = []
        return list_of_files

    def unpack_command(self, command):
        r"""
        Unpack a command from the configuration file, handling both dictionary
        and string inputs.

        This method takes a command from the configuration file, which can be
        either a dictionary or a string. If the input is a dictionary, the
        method extracts the command text and timeout from the dictionary.
        If the input is a string, the method assumes a default timeout of
        60 seconds.
        The method returns a tuple containing the command text and timeout.

        Parameters:
            command (dict or str): A command from the configuration file,
                                   which can be either a dictionary or a
                                   string.

        Returns:
            tuple: A tuple containing the command text and timeout.
        """
        if isinstance(command, dict):
            command_txt = next(iter(command))
            command_timeout = next(iter(command.values()))
        elif isinstance(command, str):
            command_txt = command
            # Default command timeout 60 seconds
            command_timeout = 60

        return command_txt, command_timeout

    def ssh_execute_ffdc_commands(
        self, ffdc_actions_for_target_type, form_filename=False
    ):
        r"""
        Send commands in the ffdc_config file to the targeted system using SSH.

        This method sends a set of commands and collects FFDC data from the
        targeted system using the SSH protocol. The method takes the
        ffdc_actions_for_target_type dictionary and an optional
        form_filename parameter as arguments.

        If form_filename is set to True, the method prepends the target type
        to the output file name. The method returns the output of the executed
        commands.

        It also prints the progress counter string + on the console.

        Parameters:
            ffdc_actions_for_target_type (dict): A dictionary containing
                                                 commands and files for the
                                                 selected remote host type.
            form_filename (bool, optional):      If True, prepends the target
                                                 type to the output file name.
                                                 Defaults to False.

        Returns:
            None
        """
        self.logger.info(
            "\n\t[Run] Executing commands on %s using %s"
            % (self.hostname, ffdc_actions_for_target_type["PROTOCOL"][0])
        )

        list_of_commands = self.get_command_list(ffdc_actions_for_target_type)
        # If command list is empty, returns
        if not list_of_commands:
            return

        progress_counter = 0
        for command in list_of_commands:
            command_txt, command_timeout = self.unpack_command(command)

            if form_filename:
                command_txt = str(command_txt % self.target_type)

            (
                cmd_exit_code,
                err,
                response,
            ) = self.ssh_remoteclient.execute_command(
                command_txt, command_timeout
            )

            if cmd_exit_code:
                self.logger.warning(
                    "\n\t\t[WARN] %s exits with code %s."
                    % (command_txt, str(cmd_exit_code))
                )
                self.logger.warning("\t\t[WARN] %s " % err)

            progress_counter += 1
            self.print_progress(progress_counter)

        self.logger.info("\n\t[Run] Commands execution completed.\t\t [OK]")

    def group_copy(self, ffdc_actions_for_target_type):
        r"""
        SCP a group of files (wildcard) from the remote host.

        This method copies a group of files from the remote host using the SCP
        protocol. The method takes the fdc_actions_for_target_type dictionary
        as an argument, which contains commands and files for the selected
        remote host type.

        Parameters:
            fdc_actions_for_target_type (dict): A dictionary containing
                                                commands and files for the
                                                selected remote host type.

        Returns:
            None
        """
        if self.ssh_remoteclient.scpclient:
            self.logger.info(
                "\n\tCopying files from remote system %s via SCP.\n"
                % self.hostname
            )

            list_of_commands = self.get_command_list(
                ffdc_actions_for_target_type
            )
            # If command list is empty, returns
            if not list_of_commands:
                return

            for command in list_of_commands:
                try:
                    command = self.yaml_env_and_plugin_vars_populate(command)
                except IndexError:
                    self.logger.error("\t\tInvalid command %s" % command)
                    continue

                (
                    cmd_exit_code,
                    err,
                    response,
                ) = self.ssh_remoteclient.execute_command(command)

                # If file does not exist, code take no action.
                # cmd_exit_code is ignored for this scenario.
                if response:
                    scp_result = self.ssh_remoteclient.scp_file_from_remote(
                        response.split("\n"), self.ffdc_dir_path
                    )
                    if scp_result:
                        self.logger.info(
                            "\t\tSuccessfully copied from "
                            + self.hostname
                            + ":"
                            + command
                        )
                else:
                    self.logger.info("\t\t%s has no result" % command)

        else:
            self.logger.info(
                "\n\n\tSkip copying files from remote system %s.\n"
                % self.hostname
            )

    def scp_ffdc(
        self,
        targ_dir_path,
        targ_file_prefix,
        form_filename,
        file_list=None,
        quiet=None,
    ):
        r"""
        SCP all files in the file_dict to the indicated directory on the local
        system.

        This method copies all files specified in the file_dict dictionary
        from the targeted system to the local system using the SCP protocol.
        The method takes the target directory path, target file prefix, and a
        boolean flag form_filename as required arguments.

        The file_dict argument is optional and contains the files to be copied.
        The quiet argument is also optional and, if set to True, suppresses
        the output of the SCP operation.

        Parameters:
            targ_dir_path (str):        The path of the directory to receive
                                        the files on the local system.
            targ_file_prefix (str):     Prefix which will be prepended to each
                                        target file's name.
            form_filename (bool):       If True, prepends the target type to
                                        the file names.
            file_dict (dict, optional): A dictionary containing the files to
                                        be copied. Defaults to None.
            quiet (bool, optional):     If True, suppresses the output of the
                                        SCP operation. Defaults to None.

        Returns:
            None
        """
        progress_counter = 0
        for filename in file_list:
            if form_filename:
                filename = str(filename % self.target_type)
            source_file_path = filename
            targ_file_path = (
                targ_dir_path + targ_file_prefix + filename.split("/")[-1]
            )

            # If source file name contains wild card, copy filename as is.
            if "*" in source_file_path:
                scp_result = self.ssh_remoteclient.scp_file_from_remote(
                    source_file_path, self.ffdc_dir_path
                )
            else:
                scp_result = self.ssh_remoteclient.scp_file_from_remote(
                    source_file_path, targ_file_path
                )

            if not quiet:
                if scp_result:
                    self.logger.info(
                        "\t\tSuccessfully copied from "
                        + self.hostname
                        + ":"
                        + source_file_path
                        + ".\n"
                    )
                else:
                    self.logger.info(
                        "\t\tFail to copy from "
                        + self.hostname
                        + ":"
                        + source_file_path
                        + ".\n"
                    )
            else:
                progress_counter += 1
                self.print_progress(progress_counter)

    def set_ffdc_default_store_path(self):
        r"""
        Set default values for self.ffdc_dir_path and self.ffdc_prefix.

        This method sets default values for the self.ffdc_dir_path and
        self.ffdc_prefix class variables.

        The collected FFDC files will be stored in the directory
        /self.location/hostname_timestr/, with individual files having the
        format timestr_filename where timestr is in %Y%m%d-%H%M%S.

        Returns:
            None
        """
        timestr = time.strftime("%Y%m%d-%H%M%S")
        self.ffdc_dir_path = (
            self.location + "/" + self.hostname + "_" + timestr + "/"
        )
        self.ffdc_prefix = timestr + "_"
        self.validate_local_store(self.ffdc_dir_path)

    # Need to verify local store path exists prior to instantiate this class.
    # This class method to validate log path before referencing this class.
    @classmethod
    def validate_local_store(cls, dir_path):
        r"""
        Ensure the specified directory exists to store FFDC files locally.

        This method checks if the provided dir_path exists. If the directory
        does not exist, the method creates it. The method does not return any
        value.

        Parameters:
            dir_path (str): The directory path where collected FFDC data files
                            will be stored.

        Returns:
            None
        """
        if not os.path.exists(dir_path):
            try:
                os.makedirs(dir_path, 0o755)
            except (IOError, OSError) as e:
                # PermissionError
                if e.errno == EPERM or e.errno == EACCES:
                    print(
                        "\tERROR: os.makedirs %s failed with"
                        " PermissionError.\n" % dir_path
                    )
                else:
                    print(
                        "\tERROR: os.makedirs %s failed with %s.\n"
                        % (dir_path, e.strerror)
                    )
                sys.exit(-1)

    def print_progress(self, progress):
        r"""
        Print the current activity progress.

        This method prints the current activity progress using the provided
        progress counter. The method does not return any value.

        Parameters:
            progress (int): The current activity progress counter.

        Returns:
            None
        """
        sys.stdout.write("\r\t" + "+" * progress)
        sys.stdout.flush()
        time.sleep(0.1)

    def verify_redfish(self):
        r"""
        Verify if the remote host has the Redfish service active.

        This method checks if the remote host has the Redfish service active
        by sending a GET request to the Redfish base URL /redfish/v1/.
        If the request is successful (status code 200), the method returns
        stdout output of the run else error message.

        Returns:
            str: Redfish service executed output.
        """
        redfish_parm = (
            "redfishtool -r "
            + self.hostname
            + ":"
            + self.port_https
            + " -S Always raw GET /redfish/v1/"
        )
        return self.run_tool_cmd(redfish_parm, True)

    def verify_ipmi(self):
        r"""
        Verify if the remote host has the IPMI LAN service active.

        This method checks if the remote host has the IPMI LAN service active
        by sending an IPMI "power status" command.

        If the command is successful (returns a non-empty response),
        else error message.

        Returns:
            str: IPMI LAN service executed output.
        """
        if self.target_type == "OPENBMC":
            ipmi_parm = (
                "ipmitool -I lanplus -C 17  -U "
                + self.username
                + " -P "
                + self.password
                + " -H "
                + self.hostname
                + " -p "
                + str(self.port_ipmi)
                + " power status"
            )
        else:
            ipmi_parm = (
                "ipmitool -I lanplus  -P "
                + self.password
                + " -H "
                + self.hostname
                + " -p "
                + str(self.port_ipmi)
                + " power status"
            )

        return self.run_tool_cmd(ipmi_parm, True)

    def run_tool_cmd(self, parms_string, quiet=False):
        r"""
        Run a CLI standard tool or script with the provided command options.

        This method runs a CLI standard tool or script with the provided
        parms_string command options. If the quiet parameter is set to True,
        the method suppresses the output of the command.
        The method returns the output of the command as a string.

        Parameters:
            parms_string (str):     The command options for the CLI tool or
                                    script.
            quiet (bool, optional): If True, suppresses the output of the
                                    command. Defaults to False.

        Returns:
            str: The output of the command as a string.
        """

        result = subprocess.run(
            [parms_string],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            shell=True,
            universal_newlines=True,
        )

        if result.stderr and not quiet:
            if self.password in parms_string:
                parms_string = parms_string.replace(self.password, "********")
            self.logger.error("\n\t\tERROR with %s " % parms_string)
            self.logger.error("\t\t" + result.stderr)

        return result.stdout

    def verify_protocol(self, protocol_list):
        r"""
        Perform a working check for the provided list of protocols.

        This method checks if the specified protocols are available on the
        remote host. The method iterates through the protocol_list and
        attempts to establish a connection using each protocol.

        If a connection is successfully established, the method append to the
        list and if any protocol fails to connect, the method ignores it.

        Parameters:
            protocol_list (list):   A list of protocols to check.

        Returns:
            list: All protocols are available list.
        """

        tmp_list = []
        if self.target_is_pingable():
            tmp_list.append("SHELL")

        for protocol in protocol_list:
            if self.remote_protocol != "ALL":
                if self.remote_protocol != protocol:
                    continue

            # Only check SSH/SCP once for both protocols
            if (
                protocol == "SSH"
                or protocol == "SCP"
                and protocol not in tmp_list
            ):
                if self.ssh_to_target_system():
                    # Add only what user asked.
                    if self.remote_protocol != "ALL":
                        tmp_list.append(self.remote_protocol)
                    else:
                        tmp_list.append("SSH")
                        tmp_list.append("SCP")

            if protocol == "TELNET":
                if self.telnet_to_target_system():
                    tmp_list.append(protocol)

            if protocol == "REDFISH":
                if self.verify_redfish():
                    tmp_list.append(protocol)
                    self.logger.info(
                        "\n\t[Check] %s Redfish Service.\t\t [OK]"
                        % self.hostname
                    )
                else:
                    self.logger.info(
                        "\n\t[Check] %s Redfish Service.\t\t [NOT AVAILABLE]"
                        % self.hostname
                    )

            if protocol == "IPMI":
                if self.verify_ipmi():
                    tmp_list.append(protocol)
                    self.logger.info(
                        "\n\t[Check] %s IPMI LAN Service.\t\t [OK]"
                        % self.hostname
                    )
                else:
                    self.logger.info(
                        "\n\t[Check] %s IPMI LAN Service.\t\t [NOT AVAILABLE]"
                        % self.hostname
                    )

        return tmp_list

    def load_env(self):
        r"""
        Load the user environment variables from a YAML file.

        This method reads the environment variables from a YAML file specified
        in the ENV_FILE environment variable. If the file is not found or
        there is an error reading the file, an exception is raised.

        The YAML file should have the following format:

        .. code-block:: yaml

            VAR_NAME: VAR_VALUE

        Where VAR_NAME is the name of the environment variable, and
        VAR_VALUE is its value.

        After loading the environment variables, they are stored in the
        self.env attribute for later use.
        """

        tmp_env_vars = {
            "hostname": self.hostname,
            "username": self.username,
            "password": self.password,
            "port_ssh": self.port_ssh,
            "port_https": self.port_https,
            "port_ipmi": self.port_ipmi,
        }

        # Updatae default Env and Dict var for both so that it can be
        # verified when referencing it throughout the code.
        for key, value in tmp_env_vars.items():
            os.environ[key] = value
            self.env_dict[key] = value

        try:
            tmp_env_dict = {}
            if self.env_vars:
                tmp_env_dict = json.loads(self.env_vars)
                # Export ENV vars default.
                for key, value in tmp_env_dict.items():
                    os.environ[key] = value
                    self.env_dict[key] = str(value)

            # Load user specified ENV config YAML.
            if self.econfig:
                with open(self.econfig, "r") as file:
                    try:
                        tmp_env_dict = yaml.load(file, Loader=yaml.SafeLoader)
                    except yaml.YAMLError as e:
                        self.logger.error(e)
                        sys.exit(-1)
                # Export ENV vars.
                for key, value in tmp_env_dict["env_params"].items():
                    os.environ[key] = str(value)
                    self.env_dict[key] = str(value)
        except json.decoder.JSONDecodeError as e:
            self.logger.error("\n\tERROR: %s " % e)
            sys.exit(-1)
        except FileNotFoundError as e:
            self.logger.error("\n\tERROR: %s " % e)
            sys.exit(-1)

        # This to mask the password from displaying on the console.
        mask_dict = self.env_dict.copy()
        for k, v in mask_dict.items():
            if k.lower().find("password") != -1:
                hidden_text = []
                hidden_text.append(v)
                password_regex = (
                    "(" + "|".join([re.escape(x) for x in hidden_text]) + ")"
                )
                mask_dict[k] = re.sub(password_regex, "********", v)

        self.logger.info(json.dumps(mask_dict, indent=8, sort_keys=False))

    def execute_plugin_block(self, plugin_cmd_list):
        r"""
        Pack the plugin commands into qualified Python string objects.

        This method processes the plugin_cmd_list argument, which is expected
        to contain a list of plugin commands read from a YAML file. The method
        iterates through the list, constructs a qualified Python string object
        for each plugin command, and returns a list of these string objects.

        Parameters:
            plugin_cmd_list (list): A list of plugin commands containing
                                    plugin names and arguments.
                                    Plugin block read from YAML
                                    [
                                     {'plugin_name':'plugin.foo_func.my_func'},
                                     {'plugin_args':[10]},
                                    ]

            Example:
                Execute and no return response
                - plugin:
                  - plugin_name: plugin.foo_func.my_func
                  - plugin_args:
                      - arg1
                      - arg2

                Execute and return a response
                - plugin:
                    - plugin_name: result = plugin.foo_func.my_func
                    - plugin_args:
                        - arg1
                        - arg2

                Execute and return multiple values response
                - plugin:
                    - plugin_name: result1,result2 = plugin.foo_func.my_func
                    - plugin_args:
                        - arg1
                        - arg2

        Returns:
            str: Execute and not response or a string value(s) responses,

        """

        # Declare a variable plugin resp that can accept any data type.
        resp: Any = ""
        args_string = ""

        try:
            idx = self.key_index_list_dict("plugin_name", plugin_cmd_list)
            # Get plugin module name
            plugin_name = plugin_cmd_list[idx]["plugin_name"]

            # Get plugin function name
            idx = self.key_index_list_dict("plugin_function", plugin_cmd_list)
            plugin_function = plugin_cmd_list[idx]["plugin_function"]

            # Equal separator means plugin function returns result.
            if " = " in plugin_function:
                # Ex. ['result', 'plugin.foo_func.my_func']
                plugin_function_args = plugin_function.split(" = ")
                # plugin func return data.
                for arg in plugin_function_args:
                    if arg == plugin_function_args[-1]:
                        plugin_function = arg
                    else:
                        plugin_resp = arg.split(",")
                        # ['result1','result2']
                        for x in plugin_resp:
                            global_plugin_list.append(x)
                            global_plugin_dict[x] = ""

            # Walk the plugin args ['arg1,'arg2']
            # If the YAML plugin statement 'plugin_args' is not declared.
            plugin_args = []
            if any("plugin_args" in d for d in plugin_cmd_list):
                idx = self.key_index_list_dict("plugin_args", plugin_cmd_list)
                if idx is not None:
                    plugin_args = plugin_cmd_list[idx].get("plugin_args", [])
                    plugin_args = self.yaml_args_populate(plugin_args)
                else:
                    plugin_args = self.yaml_args_populate([])

            plugin_args = self.update_vars_with_env_values(
                global_plugin_dict, plugin_args
            )

            """
            Example of plugin_func:
                plugin.redfish.enumerate_request(
                         "xx.xx.xx.xx:443",
                         "root",
                         "********",
                         "/redfish/v1/",
                         "json")
            """
            # For logging purpose to mask password.
            # List should be string element to join else gives TypeError
            args_string = self.print_plugin_args_string(plugin_args)

            # If user wants to debug plugins.
            self.logger.debug(
                f"\tDebug Plugin function: \n\t\t{plugin_name}."
                f"{plugin_function}{args_string}"
            )

            # For generic logging plugin info.
            self.logger.info(
                f"\tPlugin function: \n\t\t{plugin_name}."
                f"{plugin_function}()"
            )

            # Execute the plugins function with args.
            resp = execute_python_function(
                plugin_name, plugin_function, *plugin_args
            )
            self.logger.info(f"\tPlugin response = {resp}")
            # Update plugin vars dict if there is any.
            if resp != "PLUGIN_EXEC_ERROR":
                self.process_response_args_data(resp)
        except Exception as e:
            # Set the plugin error state.
            global_plugin_error_dict["exit_on_error"] = True
            self.logger.error("\tERROR: execute_plugin_block: %s" % e)
            pass

        # There is a real error executing the plugin function.
        if resp == "PLUGIN_EXEC_ERROR":
            return resp

        # Check if plugin_expects_return (int, string, list,dict etc)
        if any("plugin_expects_return" in d for d in plugin_cmd_list):
            idx = self.key_index_list_dict(
                "plugin_expects_return", plugin_cmd_list
            )
            plugin_expects = plugin_cmd_list[idx]["plugin_expects_return"]
            if plugin_expects:
                if resp:
                    if (
                        self.plugin_expect_type(plugin_expects, resp)
                        == "INVALID"
                    ):
                        self.logger.error("\tWARN: Plugin error check skipped")
                    elif not self.plugin_expect_type(plugin_expects, resp):
                        self.logger.error(
                            "\tERROR: Plugin expects return data: %s"
                            % plugin_expects
                        )
                        global_plugin_error_dict["exit_on_error"] = True
                elif not resp:
                    self.logger.error(
                        "\tERROR: Plugin func failed to return data"
                    )
                    global_plugin_error_dict["exit_on_error"] = True

        return resp

    def update_vars_with_env_values(self, ref_dict, args_list):
        r"""
        Update list elements with environment or gloable variable values.

        This method updates the list arguments in the provided list with the
        corresponding values from the reference dictionary.

        The method iterates through the dictionary and checks if each of the
        key matches an element in the list. If a match is found, the method
        replaces the key with its corresponding value in the list element. If
        the value is a string, the method replaces the key in the list element.
        If the value is not a string, the method assigns the value to the list
        element.
        The method handles exceptions and continues processing the remaining
        elements in the list.

        Example:

        Input (dict, list):
        {'global_log_store_path': 'LOG_PATH/BMC/system_20250523-000337'}
        ['ls  global_log_store_path/*.txt']

	    Output(list):
            ['ls  LOG_PATH/BMC/system_20250523-000337/*.txt']

        Parameters:
            ref_dict (dict):  A dictionary containing the environment or
                              global variable values.
            args_list (list): A list of arguments to update.

        Returns:
            list: The update list with global variables values.
        """
        # Replace keys in the string with their corresponding
        # values from the dictionary.
        for key, value in ref_dict.items():
            # Iterate through the list and check if each element matched
            # exact or in the string. If matches update the plugin element
            # in the list.
            for index, element in enumerate(args_list):
                try:
                    if isinstance(element, str):
                        # If the key is not in the list element string,
                        # then continue for the next element in the list.
                        if str(key) not in str(element):
                            continue
                        if isinstance(value, str):
                            args_list[index] = element.replace(key, value)
                        else:
                            args_list[index] = ref_dict[element]
                except KeyError as e:
                    print(f"Exception {e}")
                    pass
        return args_list

    def print_plugin_args_string(self, plugin_args):
        r"""
        Generate a string representation of plugin arguments, replacing the
        password if necessary.

        This method generates a string representation of the provided plugin
        arguments, joining them with commas. If the password is present in the
        arguments, it is replaced with "********".
        The method returns the generated string. If an exception occurs during
        the process, the method logs a debug log and returns "(None)".

        Parameters:
            plugin_args (list): A list of plugin arguments.

        Returns:
            str: The generated string representation of the plugin arguments.
        """
        try:
            plugin_args_str = "(" + ", ".join(map(str, plugin_args)) + ")"
            if self.password in plugin_args_str:
                args_string = plugin_args_str.replace(
                    self.password, "********"
                )
            else:
                args_string = plugin_args_str
        except Exception as e:
            self.logger.debug("\tWARN:Print args string : %s" % e)
            return "(None)"

        return args_string

    def process_response_args_data(self, plugin_resp):
        r"""
        Parse the plugin function response and update plugin return variables.

        This method parses the response data from a plugin function and
        updates the plugin return variables accordingly. The method takes the
        plugin_resp argument, which is expected to be the response data from a
        plugin function.

        The method handles various data types (string, bytes,
        tuple, list, int, float) and updates the global global_plugin_dict
        dictionary with the parsed response data. If there is an error during
        the process, the method logs a warning and continues with the next
        plugin block execution.

        Parameters:
           plugin_resp (Any): The response data from the plugin function.

        Returns:
            None
        """
        resp_list = []
        resp_data = ""

        # There is nothing to update the plugin response.
        if len(global_plugin_list) == 0 or plugin_resp == "None":
            return

        if isinstance(plugin_resp, str):
            resp_data = plugin_resp.strip("\r\n\t")
            resp_list.append(resp_data)
        elif isinstance(plugin_resp, bytes):
            resp_data = str(plugin_resp, "UTF-8").strip("\r\n\t")
            resp_list.append(resp_data)
        elif isinstance(plugin_resp, tuple):
            if len(global_plugin_list) == 1:
                resp_list.append(list(plugin_resp))
            else:
                resp_list = list(plugin_resp)
                resp_list = [x for x in resp_list]
        elif isinstance(plugin_resp, list):
            if len(global_plugin_list) == 1:
                resp_list.append([x.strip("\r\n\t") for x in plugin_resp])
            else:
                resp_list = [x.strip("\r\n\t") for x in plugin_resp]
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
                self.logger.warn("\tWARN: process_response_args_data: %s" % e)
                pass

        # Done updating plugin dict irrespective of pass or failed,
        # clear all the list element for next plugin block execute.
        global_plugin_list.clear()

    def yaml_args_populate(self, yaml_arg_list):
        r"""
        Decode environment and plugin variables and populate the argument list.

        This method processes the yaml_arg_list argument, which is expected to
        contain a list of arguments read from a YAML file. The method iterates
        through the list, decodes environment and plugin variables, and
        returns a populated list of arguments.

        .. code-block:: yaml

          - plugin_args:
            - arg1
            - arg2

        ['${hostname}:${port_https}', '${username}', '/redfish/v1/', 'json']

        Returns the populated plugin list
            ['xx.xx.xx.xx:443', 'root', '/redfish/v1/', 'json']

        Parameters:
            yaml_arg_list (list):   A list of arguments containing environment
                                    and plugin variables.

        Returns:
            list:   A populated list of arguments with decoded environment and
                    plugin variables.
        """
        if isinstance(yaml_arg_list, list):
            populated_list = []
            for arg in yaml_arg_list:
                if isinstance(arg, (int, float)):
                    populated_list.append(arg)
                elif isinstance(arg, str):
                    arg_str = self.yaml_env_and_plugin_vars_populate(arg)
                    populated_list.append(arg_str)
                else:
                    populated_list.append(arg)

            return populated_list

    def yaml_env_and_plugin_vars_populate(self, yaml_arg_str):
        r"""
        Update environment variables and plugin variables based on the
        provided YAML argument string.

        This method processes the yaml_arg_str argument, which is expected
        to contain a string representing environment variables and plugin
        variables in the format:

        .. code-block:: yaml

            - cat ${MY_VAR}
            - ls -AX my_plugin_var

        The method parses the string, extracts the variable names, and updates
        the corresponding environment variables and plugin variables.

        Parameters:
            yaml_arg_str (str):   A string containing environment and plugin
                                  variable definitions in YAML format.

        Returns:
            str:   The updated YAML argument string with plugin variables
                   replaced.
        """

        # Parse and convert the Plugin YAML vars string to python vars
        # Example:
        #   ${my_hostname}:${port_https} -> ['my_hostname', 'port_https']
        try:
            # Example, list of matching
            # env vars ['username', 'password', 'hostname']
            # Extra escape \ for special symbols. '\$\{([^\}]+)\}' works good.
            env_var_regex = r"\$\{([^\}]+)\}"
            env_var_names_list = re.findall(env_var_regex, yaml_arg_str)

            # If the list in empty [] nothing to update.
            if not len(env_var_names_list):
                return yaml_arg_str
            for var in env_var_names_list:
                env_var = os.environ.get(var)
                if env_var:
                    env_replace = "${" + var + "}"
                    yaml_arg_str = yaml_arg_str.replace(env_replace, env_var)
        except Exception as e:
            self.logger.error("\tERROR:yaml_env_vars_populate: %s" % e)
            pass

        """
        Parse the string for plugin vars.
        Implement the logic to update environment variables based on the
        extracted variable names.
        """
        try:
            # Example, list of plugin vars env_var_names_list
            #    ['my_hostname', 'port_https']
            global_plugin_dict_keys = set(global_plugin_dict.keys())
            # Skip env var list already populated above code block list.
            plugin_var_name_list = [
                var
                for var in global_plugin_dict_keys
                if var not in env_var_names_list
            ]

            for var in plugin_var_name_list:
                plugin_var_value = global_plugin_dict[var]
                if yaml_arg_str in global_plugin_dict:
                    """
                    If this plugin var exist but empty in dict, don't replace.
                    his is either a YAML plugin statement incorrectly used or
                    user added a plugin var which is not going to be populated.
                    """
                    if isinstance(plugin_var_value, (list, dict)):
                        """
                        List data type or dict can't be replaced, use
                        directly in plugin function call.
                        """
                        global_plugin_type_list.append(var)
                    else:
                        yaml_arg_str = yaml_arg_str.replace(
                            str(var), str(plugin_var_value)
                        )
        except (IndexError, ValueError) as e:
            self.logger.error("\tERROR: yaml_plugin_vars_populate: %s" % e)
            pass

        # From ${my_hostname}:${port_https} -> ['my_hostname', 'port_https']
        # to populated values string as
        # Example:  xx.xx.xx.xx:443 and return the string
        return yaml_arg_str

    def plugin_error_check(self, plugin_dict):
        r"""
        Process plugin error dictionary and return the corresponding error
        message.

        This method checks if any dictionary in the plugin_dict list contains
        a "plugin_error" key. If such a dictionary is found, it retrieves the
        value associated with the "plugin_error" key and returns the
        corresponding error message from the global_plugin_error_dict
        attribute.

        Parameters:
            plugin_dict (list of dict): A list of dictionaries containing
                                        plugin error information.

        Returns:
           str: The error message corresponding to the "plugin_error" value,
                or None if no error is found.
        """
        if any("plugin_error" in d for d in plugin_dict):
            for d in plugin_dict:
                if "plugin_error" in d:
                    value = d["plugin_error"]
                    return global_plugin_error_dict.get(value, None)
        return None

    def key_index_list_dict(self, key, list_dict):
        r"""
        Find the index of the first dictionary in the list that contains
        the specified key.

        Parameters:
            key (str):                 The key to search for in the
                                       dictionaries.
            list_dict (list of dict):  A list of dictionaries to search
                                       through.

        Returns:
            int: The index of the first dictionary containing the key, or -1
            if no match is found.
        """
        for i, d in enumerate(list_dict):
            if key in d:
                return i
        return -1

    def plugin_expect_type(self, type, data):
        r"""
        Check if the provided data matches the expected type.

        This method checks if the data argument matches the specified type.
        It supports the following types: "int", "float", "str", "list", "dict",
        and "tuple".

        If the type is not recognized, it logs an info message and returns
        "INVALID".

        Parameters:
            type (str): The expected data type.
            data:       The data to check against the expected type.

        Returns:
            bool or str: True if the data matches the expected type, False if
                         not, or "INVALID" if the type is not recognized.
        """
        if type == "int":
            return isinstance(data, int)
        elif type == "float":
            return isinstance(data, float)
        elif type == "str":
            return isinstance(data, str)
        elif type == "list":
            return isinstance(data, list)
        elif type == "dict":
            return isinstance(data, dict)
        elif type == "tuple":
            return isinstance(data, tuple)
        else:
            self.logger.info("\tInvalid data type requested: %s" % type)
            return "INVALID"
