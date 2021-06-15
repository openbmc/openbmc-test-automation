#!/usr/bin/env python

r"""

CLI FFDC Collector.
"""

import os
import sys
import click

# ---------Set sys.path for cli command execution---------------------------------------
# Absolute path to openbmc-test-automation/ffdc
full_path = os.path.abspath(os.path.dirname(sys.argv[0])).split('ffdc')[0]
sys.path.append(full_path)
# Walk path and append to sys.path
for root, dirs, files in os.walk(full_path):
    for found_dir in dirs:
        sys.path.append(os.path.join(root, found_dir))

from ffdc_collector import FFDCCollector


@click.command()
@click.option('-h', '--hostname', envvar='OPENBMC_HOST',
              help="ip or hostname of the target [default: OPENBMC_HOST]")
@click.option('-u', '--username', envvar='OPENBMC_USERNAME',
              help="username on targeted system [default:  OPENBMC_USERNAME]")
@click.option('-p', '--password', envvar='OPENBMC_PASSWORD',
              help="password for username on targeted system [default: OPENBMC_PASSWORD]")
@click.option('-f', '--ffdc_config', default="ffdc_config.yaml",
              show_default=True, help="YAML FFDC configuration file")
@click.option('-l', '--location', default="/tmp",
              show_default=True, help="Location to store collected FFDC data")
def cli_ffdc(hostname, username, password, ffdc_config, location):
    r"""
    Stand alone CLI to generate and collect FFDC from the selected target.

        Description of argument(s):

        hostname                Name/IP of the remote (targeting) host.
        username                User on the remote host with access to FFDC files.
        password                Password for user on remote host.
        ffdc_config             Configuration file listing commands and files for FFDC.
        location                Where to store collected FFDC.

    """
    click.echo("\n********** FFDC Starts **********")

    thisFFDC = FFDCCollector(hostname, username, password, ffdc_config, location)
    thisFFDC.collect_ffdc()

    if not thisFFDC.receive_file_list:
        click.echo("\n\tFFDC Collection from " + hostname + " has failed\n\n.")
    else:
        click.echo(str("\t" + str(len(thisFFDC.receive_file_list)))
                   + " files were retrieved from " + hostname)
        click.echo("\tFiles are stored in " + thisFFDC.ffdc_dir_path + "\n\n")

    click.echo("\n********** FFDC Finishes **********\n\n")


if __name__ == '__main__':
    cli_ffdc()
