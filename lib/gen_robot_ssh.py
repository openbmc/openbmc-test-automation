#!/usr/bin/env python

r"""
This module provides many valuable ssh functions such as sprint_connection,
execute_ssh_command, etc.
"""

import sys
import re
import socket
import paramiko
import exceptions

import gen_print as gp

from robot.libraries.BuiltIn import BuiltIn
from SSHLibrary import SSHLibrary
sshlib = SSHLibrary()


def sprint_connection(connection,
                      indent=0):

    r"""
    sprint data from the connection object to a string and return it.

    connection                      A connection object which is created by
                                    the SSHlibrary open_connection() function.
    indent                          The number of characters to indent the
                                    output.
    """

    buffer = gp.sindent("", indent)
    buffer += "connection:\n"
    indent += 2
    buffer += gp.sprint_varx("index", connection.index, 0, indent)
    buffer += gp.sprint_varx("host", connection.host, 0, indent)
    buffer += gp.sprint_varx("alias", connection.alias, 0, indent)
    buffer += gp.sprint_varx("port", connection.port, 0, indent)
    buffer += gp.sprint_varx("timeout", connection.timeout, 0, indent)
    buffer += gp.sprint_varx("newline", connection.newline, 0, indent)
    buffer += gp.sprint_varx("prompt", connection.prompt, 0, indent)
    buffer += gp.sprint_varx("term_type", connection.term_type, 0, indent)
    buffer += gp.sprint_varx("width", connection.width, 0, indent)
    buffer += gp.sprint_varx("height", connection.height, 0, indent)
    buffer += gp.sprint_varx("path_separator", connection.path_separator, 0,
                             indent)
    buffer += gp.sprint_varx("encoding", connection.encoding, 0, indent)

    return buffer


def sprint_connections(connections=None,
                       indent=0):

    r"""
    sprint data from the connections list to a string and return it.

    connections                     A list of connection objects which are
                                    created by the SSHlibrary open_connection
                                    function.  If this value is null, this
                                    function will populate with a call to the
                                    SSHlibrary get_connections() function.
    indent                          The number of characters to indent the
                                    output.
    """

    if connections is None:
        connections = sshlib.get_connections()

    buffer = ""
    for connection in connections:
        buffer += sprint_connection(connection, indent)

    return buffer


def find_connection(open_connection_args={}):

    r"""
    Find connection that matches the given connection arguments and return
    connection object.  Return False if no matching connection is found.

    Description of argument(s):
    open_connection_args            A dictionary of arg names and values which
                                    are legal to pass to the SSHLibrary
                                    open_connection function as parms/args.
                                    For a match to occur, the value for each
                                    item in open_connection_args must match
                                    the corresponding value in the connection
                                    being examined.
    """

    global sshlib

    for connection in sshlib.get_connections():
        # Create connection_dict from connection object.
        connection_dict = dict((key, str(value)) for key, value in
                               connection._config.iteritems())
        if dict(connection_dict, **open_connection_args) == connection_dict:
            return connection

    return False


def login_ssh(login_args={},
              max_login_attempts=5):

    r"""
    Login on the latest open SSH connection.  Retry on failure up to
    max_login_attempts.

    The caller is responsible for making sure there is an open SSH connection.

    Description of argument(s):
    login_args                      A dictionary containing the key/value
                                    pairs which are acceptable to the
                                    SSHLibrary login function as parms/args.
                                    At a minimum, this should contain a
                                    'username' and a 'password' entry.
    max_login_attempts              The max number of times to try logging in
                                    (in the event of login failures).
    """

    gp.lprint_executing()

    global sshlib

    # Get connection data for debug output.
    connection = sshlib.get_connection()
    gp.lprintn(sprint_connection(connection))
    for login_attempt_num in range(1, max_login_attempts + 1):
        gp.lprint_timen("Logging in to " + connection.host + ".")
        gp.lprint_var(login_attempt_num)
        try:
            out_buf = sshlib.login(**login_args)
        except Exception as login_exception:
            # Login will sometimes fail if the connection is new.
            except_type, except_value, except_traceback = sys.exc_info()
            gp.lprint_var(except_type)
            gp.lprint_varx("except_value", str(except_value))
            if except_type is paramiko.ssh_exception.SSHException and\
                    re.match(r"No existing session", str(except_value)):
                continue
            else:
                # We don't tolerate any other error so break from loop and
                # re-raise exception.
                break
        # If we get to this point, the login has worked and we can return.
        gp.lpvar(out_buf)
        return

    # If we get to this point, the login has failed on all attempts so the
    # exception will be raised again.
    raise(login_exception)


def execute_ssh_command(cmd_buf,
                        open_connection_args={},
                        login_args={},
                        print_out=0,
                        print_err=0,
                        ignore_err=1,
                        fork=0,
                        quiet=None,
                        test_mode=None):

    r"""
    Run the given command in an SSH session and return the stdout, stderr and
    the return code.

    If there is no open SSH connection, this function will connect and login.
    Likewise, if the caller has not yet logged in to the connection, this
    function will do the login.

    Description of arguments:
    cmd_buf                         The command string to be run in an SSH
                                    session.
    open_connection_args            A dictionary of arg names and values which
                                    are legal to pass to the SSHLibrary
                                    open_connection function as parms/args.
                                    At a minimum, this should contain a 'host'
                                    entry.
    login_args                      A dictionary containing the key/value
                                    pairs which are acceptable to the
                                    SSHLibrary login function as parms/args.
                                    At a minimum, this should contain a
                                    'username' and a 'password' entry.
    print_out                       If this is set, this function will print
                                    the stdout/stderr generated by the shell
                                    command.
    print_err                       If show_err is set, this function will
                                    print a standardized error report if the
                                    shell command returns non-zero.
    ignore_err                      Indicates that errors encountered on the
                                    sshlib.execute_command are to be ignored.
    fork                            Indicates that sshlib.start is to be used
                                    rather than sshlib.execute_command.
    quiet                           Indicates whether this function should run
                                    the pissuing() function which prints an
                                    "Issuing: <cmd string>" to stdout.  This
                                    defaults to the global quiet value.
    test_mode                       If test_mode is set, this function will
                                    not actually run the command.  This
                                    defaults to the global test_mode value.
    """

    gp.lprint_executing()

    # Obtain default values.
    quiet = int(gp.get_var_value(quiet, 0))
    test_mode = int(gp.get_var_value(test_mode, 0))

    if not quiet:
        gp.pissuing(cmd_buf, test_mode)
    else:
        gp.lissuing(cmd_buf, test_mode)

    if test_mode:
        return "", "", 0

    global sshlib

    # Look for existing SSH connection.
    # Prepare a search connection dictionary.
    search_connection_args = open_connection_args.copy()
    # Remove keys that don't work well for searches.
    search_connection_args.pop("timeout", None)
    connection = find_connection(search_connection_args)
    if connection:
        gp.lprint_timen("Found the following existing connection:")
        gp.lprintn(sprint_connection(connection))
        if connection.alias == "":
            index_or_alias = connection.index
        else:
            index_or_alias = connection.alias
        gp.lprint_timen("Switching to existing connection: \"" +
                        str(index_or_alias) + "\".")
        sshlib.switch_connection(index_or_alias)
    else:
        gp.lprint_timen("Connecting to " + open_connection_args['host'] + ".")
        cix = sshlib.open_connection(**open_connection_args)
        login_ssh(login_args)

    max_exec_cmd_attempts = 2
    for exec_cmd_attempt_num in range(1, max_exec_cmd_attempts + 1):
        gp.lprint_var(exec_cmd_attempt_num)
        try:
            if fork:
                sshlib.start_command(cmd_buf)
            else:
                stdout, stderr, rc = sshlib.execute_command(cmd_buf,
                                                            return_stdout=True,
                                                            return_stderr=True,
                                                            return_rc=True)
        except Exception as execute_exception:
            except_type, except_value, except_traceback = sys.exc_info()
            gp.lprint_var(except_type)
            gp.lprint_varx("except_value", str(except_value))

            if except_type is exceptions.AssertionError and\
               re.match(r"Connection not open", str(except_value)):
                login_ssh(login_args)
                # Now we must continue to next loop iteration to retry the
                # execute_command.
                continue
            if (except_type is paramiko.ssh_exception.SSHException and
                re.match(r"SSH session not active", str(except_value))) or\
               (except_type is socket.error and
                re.match(r"\[Errno 104\] Connection reset by peer",
                         str(except_value))):
                # Close and re-open a connection.
                # Note: close_connection() doesn't appear to get rid of the
                # connection.  It merely closes it.  Since there is a concern
                # about over-consumption of resources, we use
                # close_all_connections() which also gets rid of all
                # connections.
                gp.lprint_timen("Closing all connections.")
                sshlib.close_all_connections()
                gp.lprint_timen("Connecting to " +
                                open_connection_args['host'] + ".")
                cix = sshlib.open_connection(**open_connection_args)
                login_ssh(login_args)
                continue

            # We do not handle any other RuntimeErrors so we will raise the
            # exception again.
            raise(execute_exception)

        # If we get to this point, the command was executed.
        break

    if fork:
        return

    if rc != 0 and print_err:
        gp.print_var(rc, 1)
        if not print_out:
            gp.print_var(stderr)
            gp.print_var(stdout)

    if print_out:
        gp.printn(stderr + stdout)

    if not ignore_err:
        message = gp.sprint_error("The prior SSH" +
                                  " command returned a non-zero return" +
                                  " code:\n" + gp.sprint_var(rc, 1) + stderr +
                                  "\n")
        BuiltIn().should_be_equal(rc, 0, message)

    return stdout, stderr, rc
