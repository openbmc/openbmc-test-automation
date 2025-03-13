#!/usr/bin/env python3

r"""
This module provides many valuable functions such as my_parm_file.
"""

import collections
import errno
import inspect
import json
import os
import random
import shutil

# sys and os are needed to get the program dir path and program name.
import sys
import time

try:
    import ConfigParser
except ImportError:
    import configparser
try:
    import StringIO
except ImportError:
    import io

import re
import socket
import tempfile

try:
    import psutil

    psutil_imported = True
except ImportError:
    psutil_imported = False

import gen_cmd as gc
import gen_print as gp

robot_env = gp.robot_env
if robot_env:
    from robot.libraries.BuiltIn import BuiltIn
    from robot.utils import DotDict


def add_trailing_slash(dir_path):
    r"""
    Add a trailing slash to the directory path if it doesn't already have one
    and return it.

    Description of arguments:
    dir_path                        A directory path.
    """

    return os.path.normpath(dir_path) + os.path.sep


def makedirs(path, mode=0o777, quiet=None):
    r"""
    Call os.makedirs with the caller's arguments.

    This function offers 2 advantages over the base os.makedirs function:
    1) It will not fail if the directory already exists.
    2) It will print an "Issuing: os.makedirs" message.

    Description of argument(s):
    path                            The path containing the directories to be created.
    mode                            The mode or permissions to be granted to the created directories.
    quiet                           Indicates whether this function should run the print_issuing() function.
    """
    quiet = int(dft(quiet, gp.get_stack_var("quiet", 0)))
    gp.qprint_issuing("os.makedirs('" + path + "', mode=" + oct(mode) + ")")
    try:
        os.makedirs(path, mode)
    except OSError:
        pass


def rmtree(path, ignore_errors=False, onerror=None, quiet=None):
    r"""
    Call shutil.rmtree with the caller's arguments.

    This function offers this advantage over the base function:
    - It will print an "Issuing: shutil.rmtree" message.

    Description of argument(s):
    (All parms are passed directly to shutil.rmtree.  See its prolog for details)
    quiet                           Indicates whether this function should run the print_issuing() function.
    """
    quiet = int(dft(quiet, gp.get_stack_var("quiet", 0)))
    print_string = gp.sprint_executing(max_width=2000)
    print_string = re.sub(
        r"Executing: ", "Issuing: shutil.", print_string.rstrip("\n")
    )
    gp.qprintn(re.sub(r", quiet[ ]?=.*", ")", print_string))
    shutil.rmtree(path, ignore_errors, onerror)


def chdir(path, quiet=None):
    r"""
    Call os.chdir with the caller's arguments.

    This function offers this advantage over the base os.chdir function:
    - It will print an "Issuing: os.chdir" message.

    Description of argument(s):
    path                            The path of the directory to change to.
    quiet                           Indicates whether this function should run the print_issuing() function.
    """
    quiet = int(dft(quiet, gp.get_stack_var("quiet", 0)))
    gp.qprint_issuing("os.chdir('" + path + "')")
    os.chdir(path)


def which(file_path):
    r"""
    Find the full path of an executable file and return it.

    The PATH environment variable dictates the results of this function.

    Description of arguments:
    file_path                       The relative file path (e.g. "my_file" or "lib/my_file").
    """

    shell_rc, out_buf = gc.cmd_fnc_u(
        "which " + file_path, quiet=1, print_output=0, show_err=0
    )
    if shell_rc != 0:
        error_message = (
            'Failed to find complete path for file "' + file_path + '".\n'
        )
        error_message += gp.sprint_var(shell_rc, gp.hexa())
        error_message += out_buf
        if robot_env:
            BuiltIn().fail(gp.sprint_error(error_message))
        else:
            gp.print_error_report(error_message)
            return False

    file_path = out_buf.rstrip("\n")

    return file_path


def add_path(new_path, path, position=0):
    r"""
    Add new_path to path, provided that path doesn't already contain new_path, and return the result.

    Example:
    If PATH has a value of "/bin/user:/lib/user".  The following code:

    PATH = add_path("/tmp/new_path", PATH)

    will change PATH to "/tmp/new_path:/bin/user:/lib/user".

    Description of argument(s):
    new_path                        The path to be added.  This function will strip the trailing slash.
    path                            The path value to which the new_path should be added.
    position                        The position in path where the new_path should be added.  0 means it
                                    should be added to the beginning, 1 means add it as the 2nd item, etc.
                                    sys.maxsize means it should be added to the end.
    """

    path_list = list(filter(None, path.split(":")))
    new_path = new_path.rstrip("/")
    if new_path not in path_list:
        path_list.insert(int(position), new_path)
    return ":".join(path_list)


def dft(value, default):
    r"""
    Return default if value is None.  Otherwise, return value.

    This is really just shorthand as shown below.

    dft(value, default)

    vs

    default if value is None else value

    Description of arguments:
    value                           The value to be returned.
    default                         The default value to return if value is None.
    """

    return default if value is None else value


def get_mod_global(var_name, default=None, mod_name="__main__"):
    r"""
    Get module global variable value and return it.

    If we are running in a robot environment, the behavior will default to
    calling get_variable_value.

    Description of arguments:
    var_name                        The name of the variable whose value is sought.
    default                         The value to return if the global does not exist.
    mod_name                        The name of the module containing the global variable.
    """

    if robot_env:
        return BuiltIn().get_variable_value("${" + var_name + "}", default)

    try:
        module = sys.modules[mod_name]
    except KeyError:
        gp.print_error_report(
            "Programmer error - The mod_name passed to"
            + " this function is invalid:\n"
            + gp.sprint_var(mod_name)
        )
        raise ValueError("Programmer error.")

    if default is None:
        return getattr(module, var_name)
    else:
        return getattr(module, var_name, default)


def global_default(var_value, default=0):
    r"""
    If var_value is not None, return it.  Otherwise, return the global
    variable of the same name, if it exists.  If not, return default.

    This is meant for use by functions needing help assigning dynamic default
    values to their parms.  Example:

    def func1(parm1=None):

        parm1 = global_default(parm1, 0)

    Description of arguments:
    var_value                       The value being evaluated.
    default                         The value to be returned if var_value is None AND the global variable of
                                    the same name does not exist.
    """

    var_name = gp.get_arg_name(0, 1, stack_frame_ix=2)

    return dft(var_value, get_mod_global(var_name, 0))


def set_mod_global(var_value, mod_name="__main__", var_name=None):
    r"""
    Set a global variable for a given module.

    Description of arguments:
    var_value                       The value to set in the variable.
    mod_name                        The name of the module whose variable is to be set.
    var_name                        The name of the variable to set.  This defaults to the name of the
                                    variable used for var_value when calling this function.
    """

    try:
        module = sys.modules[mod_name]
    except KeyError:
        gp.print_error_report(
            "Programmer error - The mod_name passed to"
            + " this function is invalid:\n"
            + gp.sprint_var(mod_name)
        )
        raise ValueError("Programmer error.")

    if var_name is None:
        var_name = gp.get_arg_name(None, 1, 2)

    setattr(module, var_name, var_value)


def my_parm_file(prop_file_path):
    r"""
    Read a properties file, put the keys/values into a dictionary and return the dictionary.

    The properties file must have the following format:
    var_name<= or :>var_value
    Comment lines (those beginning with a "#") and blank lines are allowed and will be ignored.  Leading and
    trailing single or double quotes will be stripped from the value.  E.g.
    var1="This one"
    Quotes are stripped so the resulting value for var1 is:
    This one

    Description of arguments:
    prop_file_path                  The caller should pass the path to the properties file.
    """

    # ConfigParser expects at least one section header in the file (or you get
    # ConfigParser.MissingSectionHeaderError).  Properties files don't need those so I'll write a dummy
    # section header.

    try:
        string_file = StringIO.StringIO()
    except NameError:
        string_file = io.StringIO()

    # Write the dummy section header to the string file.
    string_file.write("[dummysection]\n")
    # Write the entire contents of the properties file to the string file.
    string_file.write(open(prop_file_path).read())
    # Rewind the string file.
    string_file.seek(0, os.SEEK_SET)

    # Create the ConfigParser object.
    try:
        config_parser = ConfigParser()
    except NameError:
        config_parser = configparser.ConfigParser(strict=False)
    # Make the property names case-sensitive.
    config_parser.optionxform = str
    # Read the properties from the string file.
    config_parser.read_file(string_file)
    # Return the properties as a dictionary.
    if robot_env:
        return DotDict(config_parser.items("dummysection"))
    else:
        return collections.OrderedDict(config_parser.items("dummysection"))


def file_to_list(file_path, newlines=0, comments=1, trim=0):
    r"""
    Return the contents of a file as a list.  Each element of the resulting
    list is one line from the file.

    Description of arguments:
    file_path                       The path to the file (relative or absolute).
    newlines                        Include newlines from the file in the results.
    comments                        Include comment lines and blank lines in the results.  Comment lines are
                                    any that begin with 0 or more spaces followed by the pound sign ("#").
    trim                            Trim white space from the beginning and end of each line.
    """

    lines = []
    file = open(file_path)
    for line in file:
        if not comments:
            if re.match(r"[ ]*#|^$", line):
                continue
        if not newlines:
            line = line.rstrip("\n")
        if trim:
            line = line.strip()
        lines.append(line)
    file.close()

    return lines


def file_to_str(*args, **kwargs):
    r"""
    Return the contents of a file as a string.

    Description of arguments:
    See file_to_list defined above for description of arguments.
    """

    return "\n".join(file_to_list(*args, **kwargs))


def append_file(file_path, buffer):
    r"""
    Append the data in buffer to the file named in file_path.

    Description of argument(s):
    file_path                       The path to a file (e.g. "/tmp/root/file1").
    buffer                          The buffer of data to be written to the file (e.g. "this and that").
    """

    with open(file_path, "a") as file:
        file.write(buffer)


def return_path_list():
    r"""
    This function will split the PATH environment variable into a PATH_LIST and return it.  Each element in
    the list will be normalized and have a trailing slash added.
    """

    PATH_LIST = os.environ["PATH"].split(":")
    PATH_LIST = [os.path.normpath(path) + os.sep for path in PATH_LIST]

    return PATH_LIST


def escape_bash_quotes(buffer):
    r"""
    Escape quotes in string and return it.

    The escape style implemented will be for use on the bash command line.

    Example:
    That's all.

    Result:
    That'\''s all.

    The result may then be single quoted on a bash command.  Example:

    echo 'That'\''s all.'

    Description of argument(s):
    buffer                          The string whose quotes are to be escaped.
    """

    return re.sub("'", "'\\''", buffer)


def quote_bash_parm(parm):
    r"""
    Return the bash command line parm with single quotes if they are needed.

    Description of arguments:
    parm                            The string to be quoted.
    """

    # If any of these characters are found in the parm string, then the string should be quoted.  This list
    # is by no means complete and should be expanded as needed by the developer of this function.
    # Spaces
    # Single or double quotes.
    # Bash variables (therefore, any string with a "$" may need quoting).
    # Glob characters: *, ?, []
    # Extended Glob characters: +, @, !
    # Bash brace expansion: {}
    # Tilde expansion: ~
    # Piped commands: |
    # Bash re-direction: >, <
    bash_special_chars = set(" '\"$*?[]+@!{}~|><")

    if any((char in bash_special_chars) for char in parm):
        return "'" + escape_bash_quotes(parm) + "'"

    if parm == "":
        parm = "''"

    return parm


def get_host_name_ip(host=None, short_name=0):
    r"""
    Get the host name and the IP address for the given host and return them as a tuple.

    Description of argument(s):
    host                            The host name or IP address to be obtained.
    short_name                      Include the short host name in the returned tuple, i.e. return host, ip
                                    and short_host.
    """

    host = dft(host, socket.gethostname())
    host_name = socket.getfqdn(host)
    try:
        host_ip = socket.gethostbyname(host)
    except socket.gaierror as my_gaierror:
        message = (
            "Unable to obtain the host name for the following host:"
            + "\n"
            + gp.sprint_var(host)
        )
        gp.print_error_report(message)
        raise my_gaierror

    if short_name:
        host_short_name = host_name.split(".")[0]
        return host_name, host_ip, host_short_name
    else:
        return host_name, host_ip


def pid_active(pid):
    r"""
    Return true if pid represents an active pid and false otherwise.

    Description of argument(s):
    pid                             The pid whose status is being sought.
    """

    try:
        os.kill(int(pid), 0)
    except OSError as err:
        if err.errno == errno.ESRCH:
            # ESRCH == No such process
            return False
        elif err.errno == errno.EPERM:
            # EPERM clearly means there's a process to deny access to
            return True
        else:
            # According to "man 2 kill" possible error values are
            # (EINVAL, EPERM, ESRCH)
            raise

    return True


def to_signed(number, bit_width=None):
    r"""
    Convert number to a signed number and return the result.

    Examples:

    With the following code:

    var1 = 0xfffffffffffffff1
    print_var(var1)
    print_var(var1, hexa())
    var1 = to_signed(var1)
    print_var(var1)
    print_var(var1, hexa())

    The following is written to stdout:
    var1:  18446744073709551601
    var1:  0x00000000fffffffffffffff1
    var1:  -15
    var1:  0xfffffffffffffff1

    The same code but with var1 set to 0x000000000000007f produces the following:
    var1:  127
    var1:  0x000000000000007f
    var1:  127
    var1:  0x000000000000007f

    Description of argument(s):
    number                          The number to be converted.
    bit_width                       The number of bits that defines a complete hex value.  Typically, this
                                    would be a multiple of 32.
    """

    if bit_width is None:
        try:
            bit_width = gp.bit_length(long(sys.maxsize)) + 1
        except NameError:
            bit_width = gp.bit_length(int(sys.maxsize)) + 1

    if number < 0:
        return number
    neg_bit_mask = 2 ** (bit_width - 1)
    if number & neg_bit_mask:
        return ((2**bit_width) - number) * -1
    else:
        return number


def get_child_pids(quiet=1):
    r"""
    Get and return a list of pids representing all first-generation processes that are the children of the
    current process.

    Example:

    children = get_child_pids()
    print_var(children)

    Output:
    children:
      children[0]:           9123

    Description of argument(s):
    quiet                           Display output to stdout detailing how this child pids are obtained.
    """

    if psutil_imported:
        # If "import psutil" worked, find child pids using psutil.
        current_process = psutil.Process()
        return [x.pid for x in current_process.children(recursive=False)]
    else:
        # Otherwise, find child pids using shell commands.
        print_output = not quiet

        ps_cmd_buf = (
            "ps --no-headers --ppid " + str(os.getpid()) + " -o pid,args"
        )
        # Route the output of ps to a temporary file for later grepping.  Avoid using " | grep" in the ps
        # command string because it creates yet another process which is of no interest to the caller.
        temp = tempfile.NamedTemporaryFile()
        temp_file_path = temp.name
        gc.shell_cmd(
            ps_cmd_buf + " > " + temp_file_path, print_output=print_output
        )
        # Sample contents of the temporary file:
        # 30703 sleep 2
        # 30795 /bin/bash -c ps --no-headers --ppid 30672 -o pid,args > /tmp/tmpqqorWY
        # Use egrep to exclude the "ps" process itself from the results collected with the prior shell_cmd
        # invocation.  Only the other children are of interest to the caller.  Use cut on the grep results to
        # obtain only the pid column.
        rc, output = gc.shell_cmd(
            "egrep -v '"
            + re.escape(ps_cmd_buf)
            + "' "
            + temp_file_path
            + " | cut -c1-5",
            print_output=print_output,
        )
        # Split the output buffer by line into a list.  Strip each element of extra spaces and convert each
        # element to an integer.
        return map(int, map(str.strip, filter(None, output.split("\n"))))


def json_loads_multiple(buffer):
    r"""
    Convert the contents of the buffer to a JSON array, run json.loads() on it and return the result.

    The buffer is expected to contain one or more JSON objects.

    Description of argument(s):
    buffer                          A string containing several JSON objects.
    """

    # Any line consisting of just "}", which indicates the end of an object, should have a comma appended.
    regex = "([\\r\\n])[\\}]([\\r\\n])"
    buffer = re.sub(regex, "\\1},\\2", buffer, 1)
    # Remove the comma from after the final object and place the whole buffer inside square brackets.
    buffer = "[" + re.sub(",([\r\n])$", "\\1}", buffer, 1) + "]"
    if gp.robot_env:
        return json.loads(buffer, object_pairs_hook=DotDict)
    else:
        return json.loads(buffer, object_pairs_hook=collections.OrderedDict)


def file_date_time_stamp():
    r"""
    Return a date/time stamp in the following format: yymmdd.HHMMSS

    This value is suitable for including in file names.  Example file1.181001.171716.status
    """

    return time.strftime("%y%m%d.%H%M%S", time.localtime(time.time()))


def get_function_stack():
    r"""
    Return a list of all the function names currently in the call stack.

    This function's name will be at offset 0.  This function's caller's name will be at offset 1 and so on.
    """

    return [str(stack_frame[3]) for stack_frame in inspect.stack()]


def username():
    r"""
    Return the username for the current process.
    """

    username = os.environ.get("USER", "")
    if username != "":
        return username
    user_num = str(os.geteuid())
    try:
        username = os.getlogin()
    except OSError:
        if user_num == "0":
            username = "root"
        else:
            username = "?"

    return username


def version_tuple(version):
    r"""
    Convert the version string to a tuple and return it.

    Description of argument(s):
    version                         A version string whose format is "n[.n]" (e.g. "3.6.3", "3", etc.).
    """

    return tuple(map(int, (version.split("."))))


def get_python_version():
    r"""
    Get and return the python version.
    """

    sys_version = sys.version
    # Strip out any revision code data (e.g. "3.6.3rc1" will become "3.6.3").
    sys_version = re.sub("rc[^ ]+", "", sys_version).split(" ")[0]
    # Remove any non-numerics, etc. (e.g. "2.7.15+" becomes ""2.7.15").
    return re.sub("[^0-9\\.]", "", sys_version)


python_version = version_tuple(get_python_version())
ordered_dict_version = version_tuple("3.6")


def create_temp_file_path(delim=":", suffix=""):
    r"""
    Create a temporary file path and return it.

    This function is appropriate for users who with to create a temporary file and:
    1) Have control over when and whether the file is deleted.
    2) Have the name of the file indicate information such as program name, function name, line, pid, etc.
    This can be an aid in debugging, cleanup, etc.

    The dir path portion of the file path will be /tmp/<username>/.  This function will create this directory
    if it doesn't already exist.

    This function will NOT create the file.  The file will NOT automatically get deleted.  It is the
    responsibility of the caller to dispose of it.

    Example:

    pgm123.py is run by user 'joe'.  It calls func1 which contains this code:

    temp_file_path = create_temp_file_path(suffix='suffix1')
    print_var(temp_file_path)

    Output:

    temp_file_path:                 /tmp/joe/pgm123.py:func1:line_55:pid_8199:831848:suffix1

    Description of argument(s):
    delim                           A delimiter to be used to separate the sub-components of the file name.
    suffix                          A suffix to include as the last sub-component of the file name.
    """

    temp_dir_path = "/tmp/" + username() + "/"
    try:
        os.mkdir(temp_dir_path)
    except FileExistsError:
        pass

    callers_stack_frame = inspect.stack()[1]
    file_name_elements = [
        gp.pgm_name,
        callers_stack_frame.function,
        "line_" + str(callers_stack_frame.lineno),
        "pid_" + str(os.getpid()),
        str(random.randint(0, 1000000)),
        suffix,
    ]
    temp_file_name = delim.join(file_name_elements)

    temp_file_path = temp_dir_path + temp_file_name

    return temp_file_path


def pause(message="Hit enter to continue..."):
    r"""
    Print the message, with time stamp, and pause until the user hits enter.

    Description of argument(s):
    message                         The message to be printed to stdout.
    """
    gp.print_time(message)
    try:
        input()
    except SyntaxError:
        pass

    return
