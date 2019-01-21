#!/usr/bin/env python

r"""
A python companion file for ipmi_client.robot.
"""

import collections
import gen_print as gp
import gen_cmd as gc
from robot.libraries.BuiltIn import BuiltIn


# Set default values for required IPMI options.
ipmi_interface = 'lanplus'
ipmi_cipher_suite = BuiltIn().get_variable_value("${IPMI_CIPHER_LEVEL}", '3')
ipmi_username = BuiltIn().get_variable_value("${IPMI_USERNAME}", "root")
ipmi_password = BuiltIn().get_variable_value("${IPMI_PASSWORD}", "0penBmc")
ipmi_host = BuiltIn().get_variable_value("${OPENBMC_HOST}")

# Create a list of the required IPMI options.
ipmi_required_options = ['I', 'C', 'U', 'P', 'H']
# The following dictionary maps the ipmitool option names (e.g. "I") to our
# more descriptive names (e.g. "interface") for the required options.
ipmi_option_name_map = {
    'I': 'interface',
    'C': 'cipher_suite',
    'U': 'username',
    'P': 'password',
    'H': 'host',
}


def create_ipmi_ext_command_string(command, **options):
    r"""
    Create and return an IPMI external command string which is fit to be run
    from a bash command line.

    Example:

    ipmi_ext_cmd = create_ipmi_ext_command_string('power status')

    Result:
    ipmitool -I lanplus -C 3 -P ******** -H x.x.x.x power status

    Example:

    ipmi_ext_cmd = create_ipmi_ext_command_string('power status', C='4')

    Result:
    ipmitool -I lanplus -C 4 -P ******** -H x.x.x.x power status

    Description of argument(s):
    command                         The ipmitool command (e.g. 'power status').
    options                         Any desired options that are understood by
                                    ipmitool (see iptmitool's help text for a
                                    complete list).  If the caller does NOT
                                    provide any of several required options
                                    (e.g. "P", i.e. password), this function
                                    will include them on the caller's behalf
                                    using default values.
    """

    new_options = collections.OrderedDict()
    for option in ipmi_required_options:
        if option in options:
            # If the caller has specified this particular option, use it in
            # preference to the default value.
            new_options[option] = options[option]
            # Delete the value from the caller's options.
            del options[option]
        else:
            # The caller hasn't specified this required option so specify it
            # for them using the global value.
            cmd_buf = 'value = ipmi_' + ipmi_option_name_map[option]
            exec(cmd_buf)
            new_options[option] = value
    # Include the remainder of the caller's options in the new options
    # dictionary.
    for key, value in options.items():
        new_options[key] = value

    return gc.create_command_string('ipmitool', command, new_options)


def verify_ipmi_user_parm_accepted():
    r"""
    Deterimine whether the OBMC accepts the '-U' ipmitool option and adjust
    the global ipmi_required_options accordingly.
    """

    # Assumption: "U" is in the global ipmi_required_options.
    global ipmi_required_options
    print_output = 0

    command_string = create_ipmi_ext_command_string('power status')
    rc, stdout = gc.shell_cmd(command_string,
                              print_output=print_output,
                              show_err=0,
                              ignore_err=1)
    gp.qprint_var(rc, 1)
    if rc == 0:
        # The OBMC accepts the ipmitool "-U" option so new further work needs
        # to be done.
        return

    # Remove the "U" option from ipmi_required_options to allow us to create a
    # command string without the "U" option.
    if 'U' in ipmi_required_options:
        del ipmi_required_options[ipmi_required_options.index('U')]
    command_string = create_ipmi_ext_command_string('power status')
    rc, stdout = gc.shell_cmd(command_string,
                              print_output=print_output,
                              show_err=0,
                              ignore_err=1)
    gp.qprint_var(rc, 1)
    if rc == 0:
        # The "U" option has been removed from the ipmi_required_options
        # global variable.
        return

    message = "Unable to run ipmitool, (with or without the '-U' option)."
    BuiltIn().fail(message)


def ipmi_setup():
    r"""
    Perform all required setup for running iptmitool commands.
    """

    verify_ipmi_user_parm_accepted()


ipmi_setup()


def process_ipmi_user_options(command):
    r"""
    Return the buffer with any ipmi_user_options pre-pended.

    Description of argument(s):
    command                         An IPMI command (e.g. "power status").
    """

    ipmi_user_options = BuiltIn().get_variable_value("${IPMI_USER_OPTIONS}", '')
    if ipmi_user_options == "":
        return command
    return ipmi_user_options + " " + command
