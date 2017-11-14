#!/usr/bin/env python

import sys
import __builtin__
import os

# python puts the program's directory path in sys.path[0].  In other words,
# the user ordinarily has no way to override python's choice of a module from
# its own dir.  We want to have that ability in our environment.  However, we
# don't want to break any established python modules that depend on this
# behavior.  So, we'll save the value from sys.path[0], delete it, import our
# modules and then restore sys.path to its original value.

save_path_0 = sys.path[0]
del sys.path[0]

from gen_print import *
from gen_arg import *
from gen_plug_in import *

# Restore sys.path[0].
sys.path.insert(0, save_path_0)


# Create parser object to process command line parameters and args.

# Create parser object.
parser = argparse.ArgumentParser(
    usage='%(prog)s [OPTIONS] [PLUG_IN_DIR_PATHS]',
    description="%(prog)s will validate the plug-in packages passed to it." +
                "  It will also print a list of the absolute plug-in" +
                " directory paths for use by the calling program.",
    formatter_class=argparse.RawTextHelpFormatter,
    prefix_chars='-+')

# Create arguments.
parser.add_argument(
    'plug_in_dir_paths',
    nargs='?',
    default="",
    help=plug_in_dir_paths_help_text + default_string)

parser.add_argument(
    '--mch_class',
    default="obmc",
    help=mch_class_help_text + default_string)

# The stock_list will be passed to gen_get_options.  We populate it with the
# names of stock parm options we want.  These stock parms are pre-defined by
# gen_get_options.
stock_list = [("test_mode", 0), ("quiet", 1), ("debug", 0)]


def exit_function(signal_number=0,
                  frame=None):

    r"""
    Execute whenever the program ends normally or with the signals that we
    catch (i.e. TERM, INT).
    """

    dprint_executing()
    dprint_var(signal_number)

    qprint_pgm_footer()


def signal_handler(signal_number, frame):

    r"""
    Handle signals.  Without a function to catch a SIGTERM or SIGINT, our
    program would terminate immediately with return code 143 and without
    calling our exit_function.
    """

    # Our convention is to set up exit_function with atexit.registr() so
    # there is no need to explicitly call exit_function from here.

    dprint_executing()

    # Calling exit prevents us from returning to the code that was running
    # when we received the signal.
    exit(0)


def validate_parms():

    r"""
    Validate program parameters, etc.  Return True or False accordingly.
    """

    gen_post_validation(exit_function, signal_handler)

    return True


def main():

    r"""
    This is the "main" function.  The advantage of having this function vs
    just doing this in the true mainline is that you can:
    - Declare local variables
    - Use "return" instead of "exit".
    - Indent 4 chars like you would in any function.
    This makes coding more consistent, i.e. it's easy to move code from here
    into a function and vice versa.
    """

    if not gen_get_options(parser, stock_list):
        return False

    if not validate_parms():
        return False

    qprint_pgm_header()

    # Access program parameter globals.
    global plug_in_dir_paths
    global mch_class

    plug_in_packages_list = return_plug_in_packages_list(plug_in_dir_paths,
                                                         mch_class)
    qpvar(plug_in_packages_list)

    # As stated in the help text, this program must print the full paths of
    # each selected plug in.
    for plug_in_dir_path in plug_in_packages_list:
        print(plug_in_dir_path)

    return True


# Main

if not main():
    exit(1)
