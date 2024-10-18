#!/usr/bin/env python3

r"""
This module contains functions having to do with machine state: get_state,
check_state, wait_state, etc.

The 'State' is a composite of many pieces of data.  Therefore, the functions
in this module define state as an ordered dictionary.  Here is an example of
some test output showing machine state:

default_state:
  default_state[chassis]:                         On
  default_state[boot_progress]:                   OSStart
  default_state[operating_system]:                BootComplete
  default_state[host]:                            Running
  default_state[os_ping]:                         1
  default_state[os_login]:                        1
  default_state[os_run_cmd]:                      1

Different users may very well have different needs when inquiring about
state.  Support for new pieces of state information may be added to this
module as needed.

By using the wait_state function, a caller can start a boot and then wait for
a precisely defined state to indicate that the boot has succeeded.  If
the boot fails, they can see exactly why by looking at the current state as
compared with the expected state.
"""

import importlib.util
import os
import re
import sys

import bmc_ssh_utils as bsu
import gen_cmd as gc
import gen_print as gp
import gen_robot_utils as gru
import gen_valid as gv
from robot.libraries.BuiltIn import BuiltIn
from robot.utils import DotDict

# NOTE: Avoid importing utils.robot because utils.robot imports state.py
# (indirectly) which will cause failures.
gru.my_import_resource("rest_client.robot")

base_path = (
    os.path.dirname(
        os.path.dirname(importlib.util.find_spec("gen_robot_print").origin)
    )
    + os.sep
)
sys.path.append(base_path + "data/")

# Previously, I had this coded:
# import variables as var
# However, we ran into a problem where a robot program did this...
# Variables           ../../lib/ras/variables.py
# Prior to doing this...
# Library            ../lib/state.py

# This caused the wrong variables.py file to be selected.  Attempts to fix this
# have failed so far.  For the moment, we will hard-code the value we need from
# the file.

SYSTEM_STATE_URI = "/xyz/openbmc_project/state/"

# The BMC code has recently been changed as far as what states are defined and
# what the state values can be.  This module now has a means of processing both
# the old style state (i.e. OBMC_STATES_VERSION = 0) and the new style (i.e.
# OBMC_STATES_VERSION = 1).
# The caller can set environment variable OBMC_STATES_VERSION to dictate
# whether we're processing old or new style states.  If OBMC_STATES_VERSION is
# not set it will default to 1.

# As of the present moment, OBMC_STATES_VERSION of 0 is for cold that is so old
# that it is no longer worthwhile to maintain.  The OBMC_STATES_VERSION 0 code
# is being removed but the OBMC_STATES_VERSION value will stay for now in the
# event that it is needed in the future.

OBMC_STATES_VERSION = int(os.environ.get("OBMC_STATES_VERSION", 1))

redfish_support_trans_state = int(
    os.environ.get("REDFISH_SUPPORT_TRANS_STATE", 0)
) or int(
    BuiltIn().get_variable_value("${REDFISH_SUPPORT_TRANS_STATE}", default=0)
)

platform_arch_type = os.environ.get(
    "PLATFORM_ARCH_TYPE", ""
) or BuiltIn().get_variable_value("${PLATFORM_ARCH_TYPE}", default="power")

# valid_os_req_states and default_os_req_states are used by the os_get_state
# function.
# valid_os_req_states is a list of state information supported by the
# get_os_state function.
valid_os_req_states = ["os_ping", "os_login", "os_run_cmd"]

# When a user calls get_os_state w/o specifying req_states,
# default_os_req_states is used as its value.
default_os_req_states = ["os_ping", "os_login", "os_run_cmd"]

# Presently, some BMCs appear to not keep time very well.  This environment
# variable directs the get_state function to use either the BMC's epoch time
# or the local epoch time.
USE_BMC_EPOCH_TIME = int(os.environ.get("USE_BMC_EPOCH_TIME", 0))

# Useful state constant definition(s).
if not redfish_support_trans_state:
    # When a user calls get_state w/o specifying req_states, default_req_states
    # is used as its value.
    default_req_states = [
        "rest",
        "chassis",
        "bmc",
        "boot_progress",
        "operating_system",
        "host",
        "os_ping",
        "os_login",
        "os_run_cmd",
    ]

    # valid_req_states is a list of sub states supported by the get_state function.
    # valid_req_states, default_req_states and master_os_up_match are used by the
    # get_state function.

    valid_req_states = [
        "ping",
        "packet_loss",
        "uptime",
        "epoch_seconds",
        "elapsed_boot_time",
        "rest",
        "chassis",
        "requested_chassis",
        "bmc",
        "requested_bmc",
        "boot_progress",
        "operating_system",
        "host",
        "requested_host",
        "attempts_left",
        "os_ping",
        "os_login",
        "os_run_cmd",
    ]

    # default_state is an initial value which may be of use to callers.
    default_state = DotDict(
        [
            ("rest", "1"),
            ("chassis", "On"),
            ("bmc", "Ready"),
            ("boot_progress", "OSStart"),
            ("operating_system", "BootComplete"),
            ("host", "Running"),
            ("os_ping", "1"),
            ("os_login", "1"),
            ("os_run_cmd", "1"),
        ]
    )

    # A match state for checking that the system is at "standby".
    standby_match_state = DotDict(
        [
            ("rest", "^1$"),
            ("chassis", "^Off$"),
            ("bmc", "^Ready$"),
            ("boot_progress", "^Off|Unspecified$"),
            ("operating_system", "^Inactive$"),
            ("host", "^Off$"),
        ]
    )

    # A match state for checking that the system is at "os running".
    os_running_match_state = DotDict(
        [
            ("chassis", "^On$"),
            ("bmc", "^Ready$"),
            ("boot_progress", "FW Progress, Starting OS|OSStart"),
            ("operating_system", "BootComplete"),
            ("host", "^Running$"),
            ("os_ping", "^1$"),
            ("os_login", "^1$"),
            ("os_run_cmd", "^1$"),
        ]
    )

    # A master dictionary to determine whether the os may be up.
    master_os_up_match = DotDict(
        [
            ("chassis", "^On$"),
            ("bmc", "^Ready$"),
            ("boot_progress", "FW Progress, Starting OS|OSStart"),
            ("operating_system", "BootComplete"),
            ("host", "^Running|Quiesced$"),
        ]
    )

    invalid_state_match = DotDict(
        [
            ("rest", "^$"),
            ("chassis", "^$"),
            ("bmc", "^$"),
            ("boot_progress", "^$"),
            ("operating_system", "^$"),
            ("host", "^$"),
        ]
    )
else:
    # When a user calls get_state w/o specifying req_states, default_req_states
    # is used as its value.
    default_req_states = [
        "redfish",
        "chassis",
        "bmc",
        "boot_progress",
        "host",
        "os_ping",
        "os_login",
        "os_run_cmd",
    ]

    # valid_req_states is a list of sub states supported by the get_state function.
    # valid_req_states, default_req_states and master_os_up_match are used by the
    # get_state function.

    valid_req_states = [
        "ping",
        "packet_loss",
        "uptime",
        "epoch_seconds",
        "elapsed_boot_time",
        "redfish",
        "chassis",
        "requested_chassis",
        "bmc",
        "requested_bmc",
        "boot_progress",
        "host",
        "requested_host",
        "attempts_left",
        "os_ping",
        "os_login",
        "os_run_cmd",
    ]

    # default_state is an initial value which may be of use to callers.
    default_state = DotDict(
        [
            ("redfish", "1"),
            ("chassis", "On"),
            ("bmc", "Enabled"),
            (
                "boot_progress",
                "SystemHardwareInitializationComplete|OSBootStarted|OSRunning",
            ),
            ("host", "Enabled"),
            ("os_ping", "1"),
            ("os_login", "1"),
            ("os_run_cmd", "1"),
        ]
    )

    # A match state for checking that the system is at "standby".
    standby_match_state = DotDict(
        [
            ("redfish", "^1$"),
            ("chassis", "^Off$"),
            ("bmc", "^Enabled$"),
            ("boot_progress", "^None$"),
            ("host", "^Disabled$"),
        ]
    )

    # A match state for checking that the system is at "os running".
    os_running_match_state = DotDict(
        [
            ("chassis", "^On$"),
            ("bmc", "^Enabled$"),
            (
                "boot_progress",
                "SystemHardwareInitializationComplete|OSBootStarted|OSRunning",
            ),
            ("host", "^Enabled$"),
            ("os_ping", "^1$"),
            ("os_login", "^1$"),
            ("os_run_cmd", "^1$"),
        ]
    )

    # A master dictionary to determine whether the os may be up.
    master_os_up_match = DotDict(
        [
            ("chassis", "^On$"),
            ("bmc", "^Enabled$"),
            (
                "boot_progress",
                "SystemHardwareInitializationComplete|OSBootStarted|OSRunning",
            ),
            ("host", "^Enabled$"),
        ]
    )

    invalid_state_match = DotDict(
        [
            ("redfish", "^$"),
            ("chassis", "^$"),
            ("bmc", "^$"),
            ("boot_progress", "^$"),
            ("host", "^$"),
        ]
    )

# Filter the states based on platform type.
if platform_arch_type == "x86":
    if not redfish_support_trans_state:
        default_req_states.remove("operating_system")
        valid_req_states.remove("operating_system")
        del default_state["operating_system"]
        del standby_match_state["operating_system"]
        del os_running_match_state["operating_system"]
        del master_os_up_match["operating_system"]
        del invalid_state_match["operating_system"]

    default_req_states.remove("boot_progress")
    valid_req_states.remove("boot_progress")
    del default_state["boot_progress"]
    del standby_match_state["boot_progress"]
    del os_running_match_state["boot_progress"]
    del master_os_up_match["boot_progress"]
    del invalid_state_match["boot_progress"]


def return_state_constant(state_name="default_state"):
    r"""
    Return the named state dictionary constant.
    """

    return eval(state_name)


def anchor_state(state):
    r"""
    Add regular expression anchors ("^" and "$") to the beginning and end of
    each item in the state dictionary passed in.  Return the resulting
    dictionary.

    Description of argument(s):
    state    A dictionary such as the one returned by the get_state()
             function.
    """

    anchored_state = state.copy()
    for key in anchored_state.keys():
        anchored_state[key] = "^" + str(anchored_state[key]) + "$"

    return anchored_state


def strip_anchor_state(state):
    r"""
    Strip regular expression anchors ("^" and "$") from the beginning and end
    of each item in the state dictionary passed in.  Return the resulting
    dictionary.

    Description of argument(s):
    state    A dictionary such as the one returned by the get_state()
             function.
    """

    stripped_state = state.copy()
    for key in stripped_state.keys():
        stripped_state[key] = stripped_state[key].strip("^$")

    return stripped_state


def expressions_key():
    r"""
    Return expressions key constant.
    """
    return "<expressions>"


def compare_states(state, match_state, match_type="and"):
    r"""
    Compare 2 state dictionaries.  Return True if they match and False if they
    don't.  Note that the match_state dictionary does not need to have an entry
    corresponding to each entry in the state dictionary.  But for each entry
    that it does have, the corresponding state entry will be checked for a
    match.

    Description of argument(s):
    state           A state dictionary such as the one returned by the
                    get_state function.
    match_state     A dictionary whose key/value pairs are "state field"/
                    "state value".  The state value is interpreted as a
                    regular expression.  Every value in this dictionary is
                    considered.  When match_type is 'and', if each and every
                    comparison matches, the two dictionaries are considered to
                    be matching.  If match_type is 'or', if any two of the
                    elements compared match, the two dictionaries are
                    considered to be matching.

                    This value may also be any string accepted by
                    return_state_constant (e.g. "standby_match_state").  In
                    such a case this function will call return_state_constant
                    to convert it to a proper dictionary as described above.

                    Finally, one special value is accepted for the key field:
                    expression_key().  If such an entry exists, its value is
                    taken to be a list of expressions to be evaluated.  These
                    expressions may reference state dictionary entries by
                    simply coding them in standard python syntax (e.g.
                    state['key1']).  What follows is an example expression:

                    "int(float(state['uptime'])) < int(state['elapsed_boot_time'])"

                    In this example, if the state dictionary's 'uptime' entry
                    is less than its 'elapsed_boot_time' entry, it would
                    qualify as a match.
    match_type      This may be 'and' or 'or'.
    """

    error_message = gv.valid_value(match_type, valid_values=["and", "or"])
    if error_message != "":
        BuiltIn().fail(gp.sprint_error(error_message))

    try:
        match_state = return_state_constant(match_state)
    except TypeError:
        pass

    default_match = match_type == "and"
    for key, match_state_value in match_state.items():
        # Blank match_state_value means "don't care".
        if match_state_value == "":
            continue
        if key == expressions_key():
            for expr in match_state_value:
                # Use python interpreter to evaluate the expression.
                match = eval(expr)
                if match != default_match:
                    return match
        else:
            try:
                match = (
                    re.match(match_state_value, str(state[key])) is not None
                )
            except KeyError:
                match = False
            if match != default_match:
                return match

    return default_match


def get_os_state(
    os_host="",
    os_username="",
    os_password="",
    req_states=default_os_req_states,
    os_up=True,
    quiet=None,
):
    r"""
    Get component states for the operating system such as ping, login,
    etc, put them into a dictionary and return them to the caller.

    Note that all substate values are strings.

    Description of argument(s):
    os_host      The DNS name or IP address of the operating system.
                 This defaults to global ${OS_HOST}.
    os_username  The username to be used to login to the OS.
                 This defaults to global ${OS_USERNAME}.
    os_password  The password to be used to login to the OS.
                 This defaults to global ${OS_PASSWORD}.
    req_states   This is a list of states whose values are being requested by
                 the caller.
    os_up        If the caller knows that the os can't possibly be up, it can
                 improve performance by passing os_up=False.  This function
                 will then simply return default values for all requested os
                 sub states.
    quiet        Indicates whether status details (e.g. curl commands) should
                 be written to the console.
                 Defaults to either global value of ${QUIET} or to 1.
    """

    quiet = int(gp.get_var_value(quiet, 0))

    # Set parm defaults where necessary and validate all parms.
    if os_host == "":
        os_host = BuiltIn().get_variable_value("${OS_HOST}")
    error_message = gv.valid_value(os_host, invalid_values=[None, ""])
    if error_message != "":
        BuiltIn().fail(gp.sprint_error(error_message))

    if os_username == "":
        os_username = BuiltIn().get_variable_value("${OS_USERNAME}")
    error_message = gv.valid_value(os_username, invalid_values=[None, ""])
    if error_message != "":
        BuiltIn().fail(gp.sprint_error(error_message))

    if os_password == "":
        os_password = BuiltIn().get_variable_value("${OS_PASSWORD}")
    error_message = gv.valid_value(os_password, invalid_values=[None, ""])
    if error_message != "":
        BuiltIn().fail(gp.sprint_error(error_message))

    invalid_req_states = [
        sub_state
        for sub_state in req_states
        if sub_state not in valid_os_req_states
    ]
    if len(invalid_req_states) > 0:
        error_message = (
            "The following req_states are not supported:\n"
            + gp.sprint_var(invalid_req_states)
        )
        BuiltIn().fail(gp.sprint_error(error_message))

    # Initialize all substate values supported by this function.
    os_ping = 0
    os_login = 0
    os_run_cmd = 0

    if os_up:
        if "os_ping" in req_states:
            # See if the OS pings.
            rc, out_buf = gc.shell_cmd(
                "ping -c 1 -w 2 " + os_host,
                print_output=0,
                show_err=0,
                ignore_err=1,
            )
            if rc == 0:
                os_ping = 1

        # Programming note: All attributes which do not require an ssh login
        # should have been processed by this point.
        master_req_login = ["os_login", "os_run_cmd"]
        req_login = [
            sub_state
            for sub_state in req_states
            if sub_state in master_req_login
        ]
        must_login = len(req_login) > 0

        if must_login:
            output, stderr, rc = bsu.os_execute_command(
                "uptime",
                quiet=quiet,
                ignore_err=1,
                time_out=20,
                os_host=os_host,
                os_username=os_username,
                os_password=os_password,
            )
            if rc == 0:
                os_login = 1
                os_run_cmd = 1
            else:
                gp.dprint_vars(output, stderr)
                gp.dprint_vars(rc, 1)

    os_state = DotDict()
    for sub_state in req_states:
        cmd_buf = "os_state['" + sub_state + "'] = str(" + sub_state + ")"
        exec(cmd_buf)

    return os_state


def get_state(
    openbmc_host="",
    openbmc_username="",
    openbmc_password="",
    os_host="",
    os_username="",
    os_password="",
    req_states=default_req_states,
    quiet=None,
):
    r"""
    Get component states such as chassis state, bmc state, etc, put them into a
    dictionary and return them to the caller.

    Note that all substate values are strings.

    Note: If elapsed_boot_time is included in req_states, it is the caller's
    duty to call set_start_boot_seconds() in order to set global
    start_boot_seconds.  elapsed_boot_time is the current time minus
    start_boot_seconds.

    Description of argument(s):
    openbmc_host      The DNS name or IP address of the BMC.
                      This defaults to global ${OPENBMC_HOST}.
    openbmc_username  The username to be used to login to the BMC.
                      This defaults to global ${OPENBMC_USERNAME}.
    openbmc_password  The password to be used to login to the BMC.
                      This defaults to global ${OPENBMC_PASSWORD}.
    os_host           The DNS name or IP address of the operating system.
                      This defaults to global ${OS_HOST}.
    os_username       The username to be used to login to the OS.
                      This defaults to global ${OS_USERNAME}.
    os_password       The password to be used to login to the OS.
                      This defaults to global ${OS_PASSWORD}.
    req_states        This is a list of states whose values are being requested
                      by the caller.
    quiet             Indicates whether status details (e.g. curl commands)
                      should be written to the console.
                      Defaults to either global value of ${QUIET} or to 1.
    """

    quiet = int(gp.get_var_value(quiet, 0))

    # Set parm defaults where necessary and validate all parms.
    if openbmc_host == "":
        openbmc_host = BuiltIn().get_variable_value("${OPENBMC_HOST}")
    error_message = gv.valid_value(openbmc_host, invalid_values=[None, ""])
    if error_message != "":
        BuiltIn().fail(gp.sprint_error(error_message))

    if openbmc_username == "":
        openbmc_username = BuiltIn().get_variable_value("${OPENBMC_USERNAME}")
    error_message = gv.valid_value(openbmc_username, invalid_values=[None, ""])
    if error_message != "":
        BuiltIn().fail(gp.sprint_error(error_message))

    if openbmc_password == "":
        openbmc_password = BuiltIn().get_variable_value("${OPENBMC_PASSWORD}")
    error_message = gv.valid_value(openbmc_password, invalid_values=[None, ""])
    if error_message != "":
        BuiltIn().fail(gp.sprint_error(error_message))

    # NOTE: OS parms are optional.
    if os_host == "":
        os_host = BuiltIn().get_variable_value("${OS_HOST}")
        if os_host is None:
            os_host = ""

    if os_username == "":
        os_username = BuiltIn().get_variable_value("${OS_USERNAME}")
        if os_username is None:
            os_username = ""

    if os_password == "":
        os_password = BuiltIn().get_variable_value("${OS_PASSWORD}")
        if os_password is None:
            os_password = ""

    invalid_req_states = [
        sub_state
        for sub_state in req_states
        if sub_state not in valid_req_states
    ]
    if len(invalid_req_states) > 0:
        error_message = (
            "The following req_states are not supported:\n"
            + gp.sprint_var(invalid_req_states)
        )
        BuiltIn().fail(gp.sprint_error(error_message))

    # Initialize all substate values supported by this function.
    ping = 0
    packet_loss = ""
    uptime = ""
    epoch_seconds = ""
    elapsed_boot_time = ""
    rest = ""
    redfish = ""
    chassis = ""
    requested_chassis = ""
    bmc = ""
    requested_bmc = ""
    # BootProgress state will get populated when state logic enumerates the
    # state URI. This is to prevent state dictionary  boot_progress value
    # getting empty when the BootProgress is NOT found, making it optional.
    boot_progress = "NA"
    operating_system = ""
    host = ""
    requested_host = ""
    attempts_left = ""

    # Get the component states.
    if "ping" in req_states:
        # See if the OS pings.
        rc, out_buf = gc.shell_cmd(
            "ping -c 1 -w 2 " + openbmc_host,
            print_output=0,
            show_err=0,
            ignore_err=1,
        )
        if rc == 0:
            ping = 1

    if "packet_loss" in req_states:
        # See if the OS pings.
        cmd_buf = (
            "ping -c 5 -w 5 "
            + openbmc_host
            + " | egrep 'packet loss' | sed -re 's/.* ([0-9]+)%.*/\\1/g'"
        )
        rc, out_buf = gc.shell_cmd(
            cmd_buf, print_output=0, show_err=0, ignore_err=1
        )
        if rc == 0:
            packet_loss = out_buf.rstrip("\n")

    if "uptime" in req_states:
        # Sometimes reading uptime results in a blank value. Call with
        # wait_until_keyword_succeeds to ensure a non-blank value is obtained.
        remote_cmd_buf = (
            "bash -c 'read uptime filler 2>/dev/null < /proc/uptime"
            + ' && [ ! -z "${uptime}" ] && echo ${uptime}\''
        )
        cmd_buf = [
            "BMC Execute Command",
            re.sub("\\$", "\\$", remote_cmd_buf),
            "quiet=1",
            "test_mode=0",
            "time_out=5",
        ]
        gp.qprint_issuing(cmd_buf, 0)
        gp.qprint_issuing(remote_cmd_buf, 0)
        try:
            stdout, stderr, rc = BuiltIn().wait_until_keyword_succeeds(
                "10 sec", "5 sec", *cmd_buf
            )
            if rc == 0 and stderr == "":
                uptime = stdout
        except AssertionError as my_assertion_error:
            pass

    if "epoch_seconds" in req_states or "elapsed_boot_time" in req_states:
        date_cmd_buf = "date -u +%s"
        if USE_BMC_EPOCH_TIME:
            cmd_buf = ["BMC Execute Command", date_cmd_buf, "quiet=${1}"]
            if not quiet:
                gp.print_issuing(cmd_buf)
            status, ret_values = BuiltIn().run_keyword_and_ignore_error(
                *cmd_buf
            )
            if status == "PASS":
                stdout, stderr, rc = ret_values
                if rc == 0 and stderr == "":
                    epoch_seconds = stdout.rstrip("\n")
        else:
            shell_rc, out_buf = gc.cmd_fnc_u(
                date_cmd_buf, quiet=quiet, print_output=0
            )
            if shell_rc == 0:
                epoch_seconds = out_buf.rstrip("\n")

    if "elapsed_boot_time" in req_states:
        global start_boot_seconds
        elapsed_boot_time = int(epoch_seconds) - start_boot_seconds

    if not redfish_support_trans_state:
        master_req_rest = [
            "rest",
            "host",
            "requested_host",
            "operating_system",
            "attempts_left",
            "boot_progress",
            "chassis",
            "requested_chassisbmcrequested_bmc",
        ]

        req_rest = [
            sub_state
            for sub_state in req_states
            if sub_state in master_req_rest
        ]
        need_rest = len(req_rest) > 0
        state = DotDict()
        if need_rest:
            cmd_buf = [
                "Read Properties",
                SYSTEM_STATE_URI + "enumerate",
                "quiet=${" + str(quiet) + "}",
                "timeout=30",
            ]
            gp.dprint_issuing(cmd_buf)
            status, ret_values = BuiltIn().run_keyword_and_ignore_error(
                *cmd_buf
            )
            if status == "PASS":
                state["rest"] = "1"
            else:
                state["rest"] = "0"

            if int(state["rest"]):
                for url_path in ret_values:
                    # Skip conflicting "CurrentHostState" URL from the enum
                    # /xyz/openbmc_project/state/hypervisor0
                    if "hypervisor0" in url_path:
                        continue

                    if platform_arch_type == "x86":
                        # Skip conflicting "CurrentPowerState" URL from the enum
                        # /xyz/openbmc_project/state/chassis_system0
                        if "chassis_system0" in url_path:
                            continue

                    for attr_name in ret_values[url_path]:
                        # Create a state key value based on the attr_name.
                        try:
                            ret_values[url_path][attr_name] = re.sub(
                                r".*\.", "", ret_values[url_path][attr_name]
                            )
                        except TypeError:
                            pass
                        # Do some key name manipulations.
                        new_attr_name = re.sub(
                            r"^Current|(State|Transition)$", "", attr_name
                        )
                        new_attr_name = re.sub(r"BMC", r"Bmc", new_attr_name)
                        new_attr_name = re.sub(
                            r"([A-Z][a-z])", r"_\1", new_attr_name
                        )
                        new_attr_name = new_attr_name.lower().lstrip("_")
                        new_attr_name = re.sub(
                            r"power", r"chassis", new_attr_name
                        )
                        if new_attr_name in req_states:
                            state[new_attr_name] = ret_values[url_path][
                                attr_name
                            ]
    else:
        master_req_rf = [
            "redfish",
            "host",
            "requested_host",
            "attempts_left",
            "boot_progress",
            "chassis",
            "requested_chassisbmcrequested_bmc",
        ]

        req_rf = [
            sub_state for sub_state in req_states if sub_state in master_req_rf
        ]
        need_rf = len(req_rf) > 0
        state = DotDict()
        if need_rf:
            cmd_buf = ["Redfish Get States"]
            gp.dprint_issuing(cmd_buf)
            try:
                status, ret_values = BuiltIn().run_keyword_and_ignore_error(
                    *cmd_buf
                )
            except Exception as ex:
                # Robot raised UserKeywordExecutionFailed error exception.
                gp.dprint_issuing("Retrying Redfish Get States")
                status, ret_values = BuiltIn().run_keyword_and_ignore_error(
                    *cmd_buf
                )

            gp.dprint_vars(status, ret_values)
            if status == "PASS":
                state["redfish"] = "1"
            else:
                state["redfish"] = "0"

            if int(state["redfish"]):
                state["chassis"] = ret_values["chassis"]
                state["host"] = ret_values["host"]
                state["bmc"] = ret_values["bmc"]
                if platform_arch_type != "x86":
                    state["boot_progress"] = ret_values["boot_progress"]

    for sub_state in req_states:
        if sub_state in state:
            continue
        if sub_state.startswith("os_"):
            # We pass "os_" requests on to get_os_state.
            continue
        cmd_buf = "state['" + sub_state + "'] = str(" + sub_state + ")"
        exec(cmd_buf)

    if os_host == "":
        # The caller has not specified an os_host so as far as we're concerned,
        # it doesn't exist.
        return state

    os_req_states = [
        sub_state for sub_state in req_states if sub_state.startswith("os_")
    ]

    if len(os_req_states) > 0:
        # The caller has specified an os_host and they have requested
        # information on os substates.

        # Based on the information gathered on bmc, we'll try to make a
        # determination of whether the os is even up.  We'll pass the result
        # of that assessment to get_os_state to enhance performance.
        os_up_match = DotDict()
        for sub_state in master_os_up_match:
            if sub_state in req_states:
                os_up_match[sub_state] = master_os_up_match[sub_state]
        os_up = compare_states(state, os_up_match)
        os_state = get_os_state(
            os_host=os_host,
            os_username=os_username,
            os_password=os_password,
            req_states=os_req_states,
            os_up=os_up,
            quiet=quiet,
        )
        # Append os_state dictionary to ours.
        state.update(os_state)

    return state


exit_wait_early_message = ""


def set_exit_wait_early_message(value):
    r"""
    Set global exit_wait_early_message to the indicated value.

    This is a mechanism by which the programmer can do an early exit from
    wait_until_keyword_succeeds() based on some special condition.

    Description of argument(s):
    value                           The value to assign to the global
                                    exit_wait_early_message.
    """

    global exit_wait_early_message
    exit_wait_early_message = value


def check_state(
    match_state,
    invert=0,
    print_string="",
    openbmc_host="",
    openbmc_username="",
    openbmc_password="",
    os_host="",
    os_username="",
    os_password="",
    quiet=None,
):
    r"""
    Check that the Open BMC machine's composite state matches the specified
    state.  On success, this keyword returns the machine's composite state as a
    dictionary.

    Description of argument(s):
    match_state       A dictionary whose key/value pairs are "state field"/
                      "state value".  The state value is interpreted as a
                      regular expression.  Example call from robot:
                      ${match_state}=  Create Dictionary  chassis=^On$
                      ...  bmc=^Ready$
                      ...  boot_progress=^OSStart$
                      ${state}=  Check State  &{match_state}
    invert            If this flag is set, this function will succeed if the
                      states do NOT match.
    print_string      This function will print this string to the console prior
                      to getting the state.
    openbmc_host      The DNS name or IP address of the BMC.
                      This defaults to global ${OPENBMC_HOST}.
    openbmc_username  The username to be used to login to the BMC.
                      This defaults to global ${OPENBMC_USERNAME}.
    openbmc_password  The password to be used to login to the BMC.
                      This defaults to global ${OPENBMC_PASSWORD}.
    os_host           The DNS name or IP address of the operating system.
                      This defaults to global ${OS_HOST}.
    os_username       The username to be used to login to the OS.
                      This defaults to global ${OS_USERNAME}.
    os_password       The password to be used to login to the OS.
                      This defaults to global ${OS_PASSWORD}.
    quiet             Indicates whether status details should be written to the
                      console.  Defaults to either global value of ${QUIET} or
                      to 1.
    """

    quiet = int(gp.get_var_value(quiet, 0))

    gp.gp_print(print_string)

    try:
        match_state = return_state_constant(match_state)
    except TypeError:
        pass

    req_states = list(match_state.keys())
    # Remove special-case match key from req_states.
    if expressions_key() in req_states:
        req_states.remove(expressions_key())
    # Initialize state.
    state = get_state(
        openbmc_host=openbmc_host,
        openbmc_username=openbmc_username,
        openbmc_password=openbmc_password,
        os_host=os_host,
        os_username=os_username,
        os_password=os_password,
        req_states=req_states,
        quiet=quiet,
    )
    if not quiet:
        gp.print_var(state)

    if exit_wait_early_message != "":
        # The exit_wait_early_message has been set by a signal handler so we
        # will exit "successfully".  It is incumbent upon the calling function
        # (e.g. wait_state) to check/clear this variable and to fail
        # appropriately.
        return state

    match = compare_states(state, match_state)

    if invert and match:
        fail_msg = (
            "The current state of the machine matches the match"
            + " state:\n"
            + gp.sprint_varx("state", state)
        )
        BuiltIn().fail("\n" + gp.sprint_error(fail_msg))
    elif not invert and not match:
        fail_msg = (
            "The current state of the machine does NOT match the"
            + " match state:\n"
            + gp.sprint_varx("state", state)
        )
        BuiltIn().fail("\n" + gp.sprint_error(fail_msg))

    return state


def wait_state(
    match_state=(),
    wait_time="1 min",
    interval="1 second",
    invert=0,
    openbmc_host="",
    openbmc_username="",
    openbmc_password="",
    os_host="",
    os_username="",
    os_password="",
    quiet=None,
):
    r"""
    Wait for the Open BMC machine's composite state to match the specified
    state.  On success, this keyword returns the machine's composite state as
    a dictionary.

    Description of argument(s):
    match_state       A dictionary whose key/value pairs are "state field"/
                      "state value".  See check_state (above) for details.
                      This value may also be any string accepted by
                      return_state_constant (e.g. "standby_match_state").
                      In such a case this function will call
                      return_state_constant to convert it to a proper
                      dictionary as described above.
    wait_time         The total amount of time to wait for the desired state.
                      This value may be expressed in Robot Framework's time
                      format (e.g. 1 minute, 2 min 3 s, 4.5).
    interval          The amount of time between state checks.
                      This value may be expressed in Robot Framework's time
                      format (e.g. 1 minute, 2 min 3 s, 4.5).
    invert            If this flag is set, this function will for the state of
                      the machine to cease to match the match state.
    openbmc_host      The DNS name or IP address of the BMC.
                      This defaults to global ${OPENBMC_HOST}.
    openbmc_username  The username to be used to login to the BMC.
                      This defaults to global ${OPENBMC_USERNAME}.
    openbmc_password  The password to be used to login to the BMC.
                      This defaults to global ${OPENBMC_PASSWORD}.
    os_host           The DNS name or IP address of the operating system.
                      This defaults to global ${OS_HOST}.
    os_username       The username to be used to login to the OS.
                      This defaults to global ${OS_USERNAME}.
    os_password       The password to be used to login to the OS.
                      This defaults to global ${OS_PASSWORD}.
    quiet             Indicates whether status details should be written to the
                      console.  Defaults to either global value of ${QUIET} or
                      to 1.
    """

    quiet = int(gp.get_var_value(quiet, 0))

    try:
        match_state = return_state_constant(match_state)
    except TypeError:
        pass

    if not quiet:
        if invert:
            alt_text = "cease to "
        else:
            alt_text = ""
        gp.print_timen(
            "Checking every "
            + str(interval)
            + " for up to "
            + str(wait_time)
            + " for the state of the machine to "
            + alt_text
            + "match the state shown below."
        )
        gp.print_var(match_state)

    if quiet:
        print_string = ""
    else:
        print_string = "#"

    debug = int(BuiltIn().get_variable_value("${debug}", "0"))
    if debug:
        # In debug we print state so no need to print the "#".
        print_string = ""
    check_state_quiet = 1 - debug
    cmd_buf = [
        "Check State",
        match_state,
        "invert=${" + str(invert) + "}",
        "print_string=" + print_string,
        "openbmc_host=" + openbmc_host,
        "openbmc_username=" + openbmc_username,
        "openbmc_password=" + openbmc_password,
        "os_host=" + os_host,
        "os_username=" + os_username,
        "os_password=" + os_password,
        "quiet=${" + str(check_state_quiet) + "}",
    ]
    gp.dprint_issuing(cmd_buf)
    try:
        state = BuiltIn().wait_until_keyword_succeeds(
            wait_time, interval, *cmd_buf
        )
    except AssertionError as my_assertion_error:
        gp.printn()
        message = my_assertion_error.args[0]
        BuiltIn().fail(message)

    if exit_wait_early_message:
        # The global exit_wait_early_message was set by a signal handler
        # indicating that we should fail.
        message = exit_wait_early_message
        # Clear the exit_wait_early_message variable for future use.
        set_exit_wait_early_message("")
        BuiltIn().fail(gp.sprint_error(message))

    if not quiet:
        gp.printn()
        if invert:
            gp.print_timen("The states no longer match:")
        else:
            gp.print_timen("The states match:")
        gp.print_var(state)

    return state


def set_start_boot_seconds(value=0):
    global start_boot_seconds
    start_boot_seconds = int(value)


set_start_boot_seconds(0)


def wait_for_comm_cycle(start_boot_seconds, quiet=None):
    r"""
    Wait for the BMC uptime to be less than elapsed_boot_time.

    This function will tolerate an expected loss of communication to the BMC.
    This function is useful when some kind of reboot has been initiated by the
    caller.

    Description of argument(s):
    start_boot_seconds  The time that the boot test started.  The format is the
                        epoch time in seconds, i.e. the number of seconds since
                        1970-01-01 00:00:00 UTC.  This value should be obtained
                        from the BMC so that it is not dependent on any kind of
                        synchronization between this machine and the target BMC
                        This will allow this program to work correctly even in
                        a simulated environment.  This value should be obtained
                        by the caller prior to initiating a reboot.  It can be
                        obtained as follows:
                        state = st.get_state(req_states=['epoch_seconds'])
    """

    quiet = int(gp.get_var_value(quiet, 0))

    # Validate parms.
    error_message = gv.valid_integer(start_boot_seconds)
    if error_message:
        BuiltIn().fail(gp.sprint_error(error_message))

    # Wait for uptime to be less than elapsed_boot_time.
    set_start_boot_seconds(start_boot_seconds)
    expr = "int(float(state['uptime'])) < int(state['elapsed_boot_time'])"
    match_state = DotDict(
        [
            ("uptime", "^[0-9\\.]+$"),
            ("elapsed_boot_time", "^[0-9]+$"),
            (expressions_key(), [expr]),
        ]
    )
    wait_state(match_state, wait_time="12 mins", interval="5 seconds")

    gp.qprint_timen("Verifying that REST/Redfish API interface is working.")
    if not redfish_support_trans_state:
        match_state = DotDict([("rest", "^1$")])
    else:
        match_state = DotDict([("redfish", "^1$")])
    state = wait_state(match_state, wait_time="5 mins", interval="2 seconds")
