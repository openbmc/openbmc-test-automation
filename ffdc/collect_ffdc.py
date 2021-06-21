#!/usr/bin/env python

r"""
CLI FFDC Collector.
"""

import os
import sys
import click

# ---------Set sys.path for cli command execution---------------------------------------
# Absolute path to openbmc-test-automation/ffdc
abs_path = os.path.abspath(os.path.dirname(sys.argv[0]))
full_path = abs_path.split('ffdc')[0]
sys.path.append(full_path)
# Walk path and append to sys.path
for root, dirs, files in os.walk(full_path):
    for found_dir in dirs:
        sys.path.append(os.path.join(root, found_dir))

from ffdc_collector import FFDCCollector


@click.command(context_settings=dict(help_option_names=['-h', '--help']))
@click.option('-r', '--remote', envvar='OPENBMC_HOST',
              help="Name/IP of the remote (targeting) host. [default: OPENBMC_HOST]")
@click.option('-u', '--username', envvar='OPENBMC_USERNAME',
              help="User on the remote host with access to FFDC files.[default: OPENBMC_USERNAME]")
@click.option('-p', '--password', envvar='OPENBMC_PASSWORD',
              help="Password for user on remote host. [default: OPENBMC_PASSWORD]")
@click.option('-f', '--ffdc_config', default=abs_path + "/ffdc_config.yaml",
              show_default=True, help="YAML Configuration file listing commands and files for FFDC.")
@click.option('-l', '--location', default="/tmp",
              show_default=True, help="Location to store collected FFDC data")
@click.option('-t', '--remote_type', default="OPENBMC",
              show_default=True, help="OS type of the remote (targeting) host. OPENBMC, RHEL, UBUNTU, AIX")
def cli_ffdc(remote, username, password, ffdc_config, location, remote_type):
    r"""
    Stand alone CLI to generate and collect FFDC from the selected target.
    """

    click.echo("\n********** FFDC (First Failure Data Collection) Starts **********")

    if input_options_ok(remote, username, password, ffdc_config):
        thisFFDC = FFDCCollector(remote, username, password, ffdc_config, location, remote_type)
        thisFFDC.collect_ffdc()

        if not thisFFDC.receive_file_list:
            click.echo("\n\tFFDC Collection from " + remote + " has failed.\n\n")
        else:
            click.echo(str("\t" + str(len(thisFFDC.receive_file_list)))
                       + " files were retrieved from " + remote)
            click.echo("\tFiles are stored in " + thisFFDC.ffdc_dir_path + "\n\n")

    click.echo("\n********** FFDC Finishes **********\n\n")


def input_options_ok(remote, username, password, ffdc_config):
    r"""
    Verify script options exist via CLI options or environment variables.
    """

    all_options_ok = True

    if not remote:
        all_options_ok = False
        print("\
        \n>>>>>\tERROR: Name/IP of the remote host is not specified in CLI options or env OPENBMC_HOST.")
    if not username:
        all_options_ok = False
        print("\
        \n>>>>>\tERROR: User on the remote host is not specified in CLI options or env OPENBMC_USERNAME.")
    if not password:
        all_options_ok = False
        print("\
        \n>>>>>\tERROR: Password for user on remote host is not specified in CLI options "
              + "or env OPENBMC_PASSWORD.")
    if not os.path.isfile(ffdc_config):
        all_options_ok = False
        print("\
        \n>>>>>\tERROR: Config file %s is not found.  Please verify path and filename." % ffdc_config)

    return all_options_ok


if __name__ == '__main__':
    cli_ffdc()
