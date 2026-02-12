#!/usr/bin/env python3

import subprocess


def execute_cmd(parms_string, quiet=False):
    r"""
    Execute a CLI standard tool or script with the provided command string.

    This function executes a provided command string using the current SHELL.
    The function takes the parms_string as an argument, which is expected
    to be a valid command to execute.

    The function also accepts an optional quiet parameter, which, if set to
    True, suppresses the output of the command.

    The function returns the output of the executed command as a string.

    Parameters:
        parms_string (str):     The command to execute from the current SHELL.
        quiet (bool, optional): If True, suppresses the output of the command.
                                Defaults to False.

    Returns:
        str: The output of the executed command as a string.
    """
    result = subprocess.run(
        [parms_string],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        shell=True,
        universal_newlines=True,
    )

    if result.stderr and not quiet:
        print("\n\t\tERROR with %s " % parms_string)
        print("\t\t" + result.stderr)

    return result.stdout
