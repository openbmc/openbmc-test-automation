#!/usr/bin/env python3

import os
import sys

from robot.libraries.BuiltIn import BuiltIn as robotBuildIn

sys.path.append(__file__.split(__file__.split("/")[-1])[0] + "../ffdc")
from ffdc_collector import ffdc_collector  # NOQA
from ssh_utility import SSHRemoteclient  # NOQA

# (Sub) String constants used for input dictionary key search
HOST = "HOST"
USER = "USERNAME"
PASSWD = "PASSWORD"
PORT_SSH = "SSH_PORT"
PORT_HTTPS = "HTTPS_PORT"
PORT_IPMI = "IPMI_PORT"
CONFIG = "CONFIG"
TYPE = "TYPE"
LOC = "LOCATION"
PROTOCOL = "PROTOCOL"
ENV_VARS = "ENV_VARS"
ECONFIG = "ECONFIG"
LOGLEVEL = "LOG"


def ffdc_robot_script_cli(**kwargs):
    r"""

    For the specified host, this method provide automation testcases the interface to
    the new ffdc collector ../ffdc/ffdc_collector.py via robot variable FFDC_DEFAULT

    variable FFDC_DEFAULT:1, by default use the existing ffdc collection method.
    variable FFDC_DEFAULT:0 use the new ffdc method

    Command examples:
    (1) Legacy ffdc collection
    python3 -m robot -v OPENBMC_HOST:<> -v OPENBMC_USERNAME:<> \
                                        -v OPENBMC_PASSWORD:<> ./tools/myffdc.robot
    (2) New ffdc collection
    python3 -m robot -v OPENBMC_HOST:<> -v OPENBMC_USERNAME:<> \
                        -v OPENBMC_PASSWORD:<> -v FFDC_DEFAULT:0  ./tools/myffdc.robot

    Description of argument(s)in dictionary: xx can be anything appropriate

        xx_HOST:hostname                name/ip of the targeted (remote) system
        xx_USERNAME:username            user on the targeted system with access to FFDC files
        xx_PASSWORD:password            password for user on targeted system
        xx_CONFIG:ffdc_config           configuration file listing commands and files for FFDC
        xx_LOCATION:location            where to store collected FFDC.  Default: <current dir>/logs/
        xx_TYPE:remote_type             os type of the remote host.
        xx_PROTOCOL:remote_protocol     Protocol to use to collect data. Default: 'ALL'
        ENV_VAR:env_vars                User define CLI env vars '{"key : "value"}'. Default: ""
        ECONFIG:econfig                 User define env vars YAML file. Default: ""
        LOG_LEVEL:log_level             CRITICAL, ERROR, WARNING, INFO, DEBUG. Default: INFO

    Code examples:
    (1) openbmc_ffdc.robot activate this method with no parm
        Run Keyword If  ${FFDC_DEFAULT} == ${1}  FFDC
    ...    ELSE  ffdc_robot_script_cli

    (2) Method invocation with parms
        ffdc_from = {'OS_HOST' : 'os host name or ip',
                     'OS_USERNAME' : 'os username',
                     'OS_PASSWORD' : 'password for os_username',
                     'OS_TYPE'     : 'os_type, ubuntu, rhel, aix, etc',
                    }
        ffdc_robot_script_cli(ffdc_from)

    """

    robotBuildIn().log_to_console("Collecting FFDC - CLI log collector script")

    if not kwargs:
        dict_of_parms = {}
        # When method is invoked with no parm,
        # use robot variables
        # OPENBMC_HOST, OPENBMC_USERNAME, OPENBMC_PASSWORD, BMC (type)
        dict_of_parms["OPENBMC_HOST"] = robotBuildIn().get_variable_value(
            "${OPENBMC_HOST}", default=None
        )
        dict_of_parms["OPENBMC_USERNAME"] = robotBuildIn().get_variable_value(
            "${OPENBMC_USERNAME}", default=None
        )
        dict_of_parms["OPENBMC_PASSWORD"] = robotBuildIn().get_variable_value(
            "${OPENBMC_PASSWORD}", default=None
        )
        dict_of_parms["SSH_PORT"] = robotBuildIn().get_variable_value(
            "${SSH_PORT}", default=22
        )
        dict_of_parms["HTTPS_PORT"] = robotBuildIn().get_variable_value(
            "${HTTPS_PORT}", default=443
        )
        dict_of_parms["IPMI_PORT"] = robotBuildIn().get_variable_value(
            "${IPMI_PORT}", default=623
        )
        dict_of_parms["REMOTE_TYPE"] = "BMC"

        run_ffdc_collector(dict_of_parms)

    else:
        if isinstance(kwargs, dict):
            # When method is invoked with user defined dictionary,
            # dictionary keys has the following format
            # xx_HOST; xx_USERNAME, xx_PASSWORD, xx_TYPE
            # where xx is one of BMC, OS, or os_type LINUX/UBUNTU/AIX
            run_ffdc_collector(**kwargs)


def run_ffdc_collector(dict_of_parm):
    r"""

    Process input parameters and collect information

    Description of argument(s)in dictionary: xx can be anything appropriate

        xx_HOST:hostname                name/ip of the targeted (remote) system
        xx_USERNAME:username            user on the targeted system with access to FFDC files
        xx_PASSWORD:password            password for user on targeted system
        xx_CONFIG:ffdc_config           configuration file listing commands and files for FFDC
        xx_LOCATION:location            where to store collected FFDC.  Default: <current dir>/logs/
        xx_TYPE:remote_type             os type of the remote host.
        xx_PROTOCOL:remote_protocol     Protocol to use to collect data. Default: 'ALL'
        ENV_VAR:env_vars                User define CLI env vars '{"key : "value"}'. Default: ""
        ECONFIG:econfig                 User define env vars YAML file. Default: ""
        LOG_LEVEL:log_level             CRITICAL, ERROR, WARNING, INFO, DEBUG. Default: INFO

    """

    # Clear local variables
    remote = None
    username = None
    password = None
    config = None
    location = None
    remote_type = None
    protocol = None
    env_vars = None
    econfig = None
    log_level = None

    # Process input key/value pairs
    for key in dict_of_parm.keys():
        if HOST in key:
            remote = dict_of_parm[key]
        elif USER in key:
            username = dict_of_parm[key]
        elif PASSWD in key:
            password = dict_of_parm[key]
        elif PORT_SSH in key:
            port_ssh = dict_of_parm[key]
        elif PORT_HTTPS in key:
            port_https = dict_of_parm[key]
        elif PORT_IPMI in key:
            port_ipmi = dict_of_parm[key]
        elif CONFIG in key:
            config = dict_of_parm[key]
        elif LOC in key:
            location = dict_of_parm[key]
        elif TYPE in key:
            remote_type = dict_of_parm[key]
        elif PROTOCOL in key:
            protocol = dict_of_parm[key]
        elif ENV_VARS in key:
            env_vars = dict_of_parm[key]
        elif ECONFIG in key:
            econfig = dict_of_parm[key]
        elif LOGLEVEL in key:
            log_level = dict_of_parm[key]

    # Set defaults values for parms
    # that are not specified with input and have acceptable defaults.
    if not location:
        # Default FFDC store location
        location = (
            robotBuildIn().get_variable_value("${EXECDIR}", default=None)
            + "/logs"
        )
        ffdc_collector.validate_local_store(location)

    if not config:
        # Default FFDC configuration
        script_path = os.path.dirname(os.path.abspath(__file__))
        config = script_path + "/../ffdc/ffdc_config.yaml"

    if not protocol:
        protocol = "ALL"

    if not env_vars:
        env_vars = ""

    if not econfig:
        econfig = ""

    if not log_level:
        log_level = "INFO"

    # If minimum required inputs are met, go collect.
    if remote and username and password and remote_type:
        # Execute data collection
        this_ffdc = ffdc_collector(
            remote,
            username,
            password,
            port_ssh,
            port_https,
            port_ipmi,
            config,
            location,
            remote_type,
            protocol,
            env_vars,
            econfig,
            log_level,
        )
        this_ffdc.collect_ffdc()

        # If original ffdc request is for BMC,
        #  attempt to also collect ffdc for HOST_OS if possible.
        if remote_type.upper() == "BMC":
            os_host = robotBuildIn().get_variable_value(
                "${OS_HOST}", default=None
            )
            os_username = robotBuildIn().get_variable_value(
                "${OS_USERNAME}", default=None
            )
            os_password = robotBuildIn().get_variable_value(
                "${OS_PASSWORD}", default=None
            )

            if os_host and os_username and os_password:
                os_type = get_os_type(os_host, os_username, os_password)
                if os_type:
                    os_ffdc = ffdc_collector(
                        os_host,
                        os_username,
                        os_password,
                        config,
                        location,
                        os_type,
                        protocol,
                        env_vars,
                        econfig,
                        log_level,
                    )
                    os_ffdc.collect_ffdc()


def get_os_type(os_host, os_username, os_password):
    os_type = None

    # If HOST_OS is pingable
    if os.system("ping -c 1 " + os_host) == 0:
        r"""
        Open a ssh connection to targeted system.
        """
        ssh_remoteclient = SSHRemoteclient(os_host, os_username, os_password)

        if ssh_remoteclient.ssh_remoteclient_login():
            # Find OS_TYPE
            cmd_exit_code, err, response = ssh_remoteclient.execute_command(
                "uname"
            )
            os_type = response.strip()

            # If HOST_OS is linux, expands os_type to one of
            # the 2 linux distros that have more details in ffdc_config.yaml
            if os_type.upper() == "LINUX":
                (
                    cmd_exit_code,
                    err,
                    response,
                ) = ssh_remoteclient.execute_command("cat /etc/os-release")
                linux_distro = response
                if "redhat" in linux_distro:
                    os_type = "RHEL"
                elif "ubuntu" in linux_distro:
                    os_type = "UBUNTU"

        if ssh_remoteclient:
            ssh_remoteclient.ssh_remoteclient_disconnect()

    return os_type
