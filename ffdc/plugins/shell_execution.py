import subprocess


def execute_cmd(parms_string, quiet=False):
    r"""
    Run CLI standard tool or scripts.

    Description of variable:
    parms_string         Command to execute from the current SHELL.
    quiet                do not print tool error message if True
    """

    result = subprocess.run([parms_string],
                            stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE,
                            shell=True,
                            universal_newlines=True)

    if result.stderr and not quiet:
        print('\n\t\tERROR with %s ' % parms_string)
        print('\t\t' + result.stderr)

    return result.stdout
