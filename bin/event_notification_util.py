#!/usr/bin/env python

r"""
See help text for details.
"""

import sys

save_dir_path = sys.path.pop(0)

modules = ['gen_arg', 'gen_print', 'gen_valid', 'event_notification']
for module in modules:
    exec("from " + module + " import *")

sys.path.insert(0, save_dir_path)

parser = argparse.ArgumentParser(
    usage='%(prog)s [OPTIONS]',
    description="%(prog)s will subscribe and receive event notifications when "
                + "properties change for the given dbus path.",
    formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    prefix_chars='-+')
parser.add_argument(
    '--host',
    default='',
    help='The host name or IP of the system to subscribe to.')
parser.add_argument(
    '--username',
    default='root',
    help='The username for the host system.')
parser.add_argument(
    '--password',
    default='',
    help='The password for the host system.')
parser.add_argument(
    '--dbus_path',
    default='',
    help='The path to be monitored (e.g. "/xyz/openbmc_project/sensors").')
parser.add_argument(
    '--enable_trace',
    choices=[0, 1],
    default=0,
    help='Indicates that trace needs to be enabled.')


# Populate stock_list with options we want.
stock_list = [("test_mode", 0), ("quiet", 0), ("debug", 0)]


def main():
    gen_setup()
    my_event = event_notification(host, username, password)
    event_notifications = my_event.subscribe(dbus_path, enable_trace)
    print_var(event_notifications, fmt=[no_header(), strip_brackets()])


main()
