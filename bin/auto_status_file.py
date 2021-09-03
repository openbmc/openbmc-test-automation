#!/usr/bin/env python3

r"""
See help text for details.
"""

import sys
import subprocess
import re

save_dir_path = sys.path.pop(0)

modules = ['gen_arg', 'gen_print', 'gen_valid', 'gen_misc', 'gen_cmd', 'var_funcs']
for module in modules:
    exec("from " + module + " import *")

sys.path.insert(0, save_dir_path)

parser = argparse.ArgumentParser(
    usage='%(prog)s [OPTIONS]',
    description="%(prog)s will create a status file path name adhering to the"
                + " following pattern: <status dir path>/<prefix>.yymmdd."
                + "hhmmss.status.  It will then run the command string and"
                + " direct its stdout/stderr to the status file and optionally"
                + " to stdout.  This dual output streaming will be"
                + " accomplished using either the \"script\" or the \"tee\""
                + " program.  %(prog)s will also set and export environment"
                + " variable \"AUTO_STATUS_FILE_PATH\" for the benefit of"
                + " child programs.",
    formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    prefix_chars='-+')

parser.add_argument(
    '--status_dir_path',
    default='',
    help="The path to the directory where the status file will be created."
         + "%(default)s The default value is obtained from environment"
         + " variable \"${STATUS_DIR_PATH}\", if set or from \"${HOME}/"
         + "status/\".")

parser.add_argument(
    '--prefix',
    default='',
    help="The prefix for the generated file name.%(default)s The default value"
         + " is the command portion (i.e. the first token) of the command"
         + " string.")

parser.add_argument(
    '--status_file_name',
    default='',
    help="This allows the user to explicitly specify the status file name.  If"
         + " this argument is not used, %(prog)s composes a status file name."
         + "  If this argument is specified, the \"--prefix\" argument is"
         + " ignored.")

parser.add_argument(
    '--stdout',
    default=1,
    type=int,
    choices=[1, 0],
    help="Indicates that stdout/stderr from the command string execution"
         + " should be written to stdout as well as to the status file.")

parser.add_argument(
    '--tee',
    default=1,
    type=int,
    choices=[1, 0],
    help="Indicates that \"tee\" rather than \"script\" should be used.")

parser.add_argument(
    '--show_url',
    default=0,
    type=int,
    choices=[1, 0],
    help="Indicates that the status file path shown should be shown in the"
         + " form of a url.  If the output is to be viewed from a browser,"
         + " this may well become a clickable link.  Note that the"
         + " get_file_path_url.py program must be found in the \"PATH\""
         + " environment variable for this argument to be effective.")

parser.add_argument(
    'command_string',
    default='',
    nargs='*',
    help="The command string to be run.%(default)s")

# Populate stock_list with options we want.
stock_list = [("test_mode", 0), ("quiet", 1), ("debug", 0)]


def validate_parms():
    r"""
    Validate program parameters, etc.
    """

    global status_dir_path
    global command_string

    # Convert command_string from list to string.
    command_string = " ".join(command_string)
    set_pgm_arg(command_string)
    valid_value(command_string)

    if status_dir_path == "":
        status_dir_path = \
            os.environ.get("STATUS_DIR_PATH",
                           os.environ.get("HOME") + "/status/")
    status_dir_path = add_trailing_slash(status_dir_path)
    set_pgm_arg(status_dir_path)
    valid_dir_path(status_dir_path)

    global prefix
    global status_file_name
    if status_file_name == "":
        if prefix == "":
            prefix = command_string.split(" ")[0]
            # File extensions (e.g. ".sh", ".py", .etc), look clumsy in status file names.
            extension_regex = "\\.[a-zA-Z0-9]{1,3}$"
            prefix = re.sub(extension_regex, "", prefix)
            set_pgm_arg(prefix)
        status_file_name = prefix + "." + file_date_time_stamp() + ".status"
        set_pgm_arg(status_file_name)

    global status_file_path

    status_file_path = status_dir_path + status_file_name
    # Set environment variable for the benefit of child programs.
    os.environ['AUTO_STATUS_FILE_PATH'] = status_file_path
    # Set deprecated but still used AUTOSCRIPT_STATUS_FILE_PATH value.
    os.environ['AUTOSCRIPT_STATUS_FILE_PATH'] = status_file_path


def script_func(command_string, status_file_path):
    r"""
    Run the command string producing both stdout and file output via the script command and return the
    shell_rc.

    Description of argument(s):
    command_string                  The command string to be run.
    status_file_path                The path to the status file which is to contain a copy of all stdout.
    """

    cmd_buf = "script -a -q -f " + status_file_path + " -c '" \
        + escape_bash_quotes(command_string) + " ; printf \"\\n" \
        + sprint_varx(ret_code_str, "${?}").rstrip("\n") + "\\n\"'"
    qprint_issuing(cmd_buf)
    sub_proc = subprocess.Popen(cmd_buf, shell=True)
    sub_proc.communicate()
    shell_rc = sub_proc.returncode

    # Retrieve return code by examining ret_code_str output statement from status file.
    # Example text to be analyzed.
    # auto_status_file_ret_code:                        127
    cmd_buf = "tail -n 10 " + status_file_path + " | egrep -a \"" \
        + ret_code_str + ":[ ]+\""
    rc, output = shell_cmd(cmd_buf)
    key, value = parse_key_value(output)
    shell_rc = int(value)

    return shell_rc


def tee_func(command_string, status_file_path):
    r"""
    Run the command string producing both stdout and file output via the tee command and return the shell_rc.

    Description of argument(s):
    command_string                  The command string to be run.
    status_file_path                The path to the status file which is to contain a copy of all stdout.
    """

    cmd_buf = "set -o pipefail ; " + command_string + " 2>&1 | tee -a " \
        + status_file_path
    qprint_issuing(cmd_buf)
    sub_proc = subprocess.Popen(cmd_buf, shell=True)
    sub_proc.communicate()
    shell_rc = sub_proc.returncode

    print
    print_varx(ret_code_str, shell_rc)
    with open(status_file_path, "a") as status_file:
        # Append ret code string and status_file_path to end of status file.
        status_file.write("\n" + sprint_varx(ret_code_str, shell_rc))

    return shell_rc


def main():

    gen_setup()

    set_term_options(term_requests={'pgm_names': [command_string.split(" ")[0]]})

    global ret_code_str
    ret_code_str = re.sub("\\.py$", "", pgm_name) + "_ret_code"

    global show_url
    if show_url:
        shell_rc, output = shell_cmd("which get_file_path_url.py", show_err=0)
        if shell_rc != 0:
            show_url = 0
            set_pgm_arg(show_url)
        else:
            shell_rc, status_file_url = shell_cmd("get_file_path_url.py "
                                                  + status_file_path)
            status_file_url = status_file_url.rstrip("\n")

    # Print status file path/url to stdout and to status file.
    with open(status_file_path, "w+") as status_file:
        if show_url:
            print_var(status_file_url)
            status_file.write(sprint_var(status_file_url))
        else:
            print_var(status_file_path)
            status_file.write(sprint_var(status_file_path))

    if stdout:
        if tee:
            shell_rc = tee_func(command_string, status_file_path)
        else:
            shell_rc = script_func(command_string, status_file_path)
        if show_url:
            print_var(status_file_url)
        else:
            print_var(status_file_path)
    else:
        cmd_buf = command_string + " >> " + status_file_path + " 2>&1"
        shell_rc, output = shell_cmd(cmd_buf, show_err=0)
        with open(status_file_path, "a") as status_file:
            # Append ret code string and status_file_path to end of status
            # file.
            status_file.write("\n" + sprint_varx(ret_code_str, shell_rc))

    # Append status_file_path print statement to end of status file.
    with open(status_file_path, "a") as status_file:
        if show_url:
            status_file.write(sprint_var(status_file_url))
        else:
            status_file.write(sprint_var(status_file_path))
    exit(shell_rc)


main()
