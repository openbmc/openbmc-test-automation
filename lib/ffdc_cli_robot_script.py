#!/usr/bin/env python3

import os
import sys

sys.path.append(__file__.split(__file__.split("/")[-1])[0] + "../ffdc")
from ffdc_collector import ffdc_collector

from robot.libraries.BuiltIn import BuiltIn as robotBuildIn

# String contants for keys
HOST = "HOST"
USER = "USERNAME"
PASSWD = "PASSWORD"
CONFIG = "CONFIG"
TYPE = "TYPE"
LOC = "LOCATION"
PROTOCOL = "PROTOCOL"
ENV_VARS = "ENV_VARS"
ECONFIG = "ECONFIG"
LOGLEVEL = "LOG"

def ffdc_robot_script_cli(**kwargs):

    if not kwargs:
        dict_of_parms = {}
        # When method is invoked with no parm,
        # use robot variables
        # OPENBMC_HOST, OPENBMC_USERNAME, OPENBMC_PASSWORD, OPENBMC (type)
        dict_of_parms["OPENBMC_HOST"] = \
                    robotBuildIn().get_variable_value("${OPENBMC_HOST}", default=None)
        dict_of_parms["OPENBMC_USERNAME"] = \
                    robotBuildIn().get_variable_value("${OPENBMC_USERNAME}", default=None)
        dict_of_parms["OPENBMC_PASSWORD"] = \
                    robotBuildIn().get_variable_value("${OPENBMC_PASSWORD}", default=None)
        dict_of_parms["REMOTE_TYPE"] = "OPENBMC"

        run_ffdc_collector(dict_of_parms)

    else:
        if isinstance(kwargs, dict):
            # When method is invoked with user defined dictionary,
            # dictionary keys has the following format
            # xx_HOST; xx_USERNAME, xx_PASSWORD, xx_TYPE
            # where xx is one of OPENBMC, OS, or os_type LINUX/UBUNTU/AIX
            run_ffdc_collector(**kwargs)

def run_ffdc_collector(dict_of_parm):

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
    # that are not specified with input and have acceptable default
    if not location:
        # Default FFDC store location
        location = robotBuildIn().get_variable_value("${EXECDIR}", default=None) + "/logs"
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
    if (remote and username and password and type):
        # Execute data collection
        thisFFDC = ffdc_collector(remote,
                                  username,
                                  password,
                                  config,
                                  location,
                                  remote_type,
                                  protocol,
                                  env_vars,
                                  econfig,
                                  log_level)
        thisFFDC.collect_ffdc()
