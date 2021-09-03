#!/usr/bin/env python3

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
@click.option('-r', '--remote',
              help="Hostname/IP of the remote host")
@click.option('-u', '--username',
              help="Username of the remote host.")
@click.option('-p', '--password',
              help="Password of the remote host.")
@click.option('-c', '--config', default=abs_path + "/ffdc_config.yaml",
              show_default=True, help="YAML Configuration file for log collection.")
@click.option('-l', '--location', default="/tmp",
              show_default=True, help="Location to save logs")
@click.option('-t', '--type',
              help="OS type of the remote (targeting) host. OPENBMC, RHEL, UBUNTU, SLES, AIX")
@click.option('-rp', '--protocol', default="ALL",
              show_default=True,
              help="Select protocol to communicate with remote host.")
@click.option('-e', '--env_vars', show_default=True,
              help="Environment variables e.g: {'var':value}")
@click.option('-ec', '--econfig', show_default=True,
              help="Predefine environment variables, refer en_vars_template.yaml ")
@click.option('--log_level', default="INFO",
              show_default=True,
              help="Log level (CRITICAL, ERROR, WARNING, INFO, DEBUG)")
def cli_ffdc(remote,
             username,
             password,
             config,
             location,
             type,
             protocol,
             env_vars,
             econfig,
             log_level):
    r"""
    Stand alone CLI to generate and collect FFDC from the selected target.
    """

    click.echo("\n********** FFDC (First Failure Data Collection) Starts **********")

    if input_options_ok(remote, username, password, config, type):
        thisFFDC = FFDCCollector(remote,
                                 username,
                                 password,
                                 config,
                                 location,
                                 type,
                                 protocol,
                                 env_vars,
                                 econfig,
                                 log_level)
        thisFFDC.collect_ffdc()

        if len(os.listdir(thisFFDC.ffdc_dir_path)) == 0:
            click.echo("\n\tFFDC Collection from " + remote + " has failed.\n\n")
        else:
            click.echo(str("\n\t" + str(len(os.listdir(thisFFDC.ffdc_dir_path)))
                           + " files were retrieved from " + remote))
            click.echo("\tFiles are stored in " + thisFFDC.ffdc_dir_path)

        click.echo("\tTotal elapsed time " + thisFFDC.elapsed_time + "\n\n")
    click.echo("\n********** FFDC Finishes **********\n\n")


def input_options_ok(remote, username, password, config, type):
    r"""
    Verify script options exist via CLI options or environment variables.
    """

    all_options_ok = True

    if not remote:
        all_options_ok = False
        print("\
        \n\tERROR: Name/IP of the remote host is not specified in CLI options.")
    if not username:
        all_options_ok = False
        print("\
        \n\tERROR: User of the remote host is not specified in CLI options.")
    if not password:
        all_options_ok = False
        print("\
        \n\tERROR: Password of the user remote host is not specified in CLI options.")
    if not type:
        all_options_ok = False
        print("\
        \n\tERROR: Remote host os type is not specified in CLI options.")
    if not os.path.isfile(config):
        all_options_ok = False
        print("\
        \n\tERROR: Config file %s is not found.  Please verify path and filename." % config)

    return all_options_ok


if __name__ == '__main__':
    cli_ffdc()
