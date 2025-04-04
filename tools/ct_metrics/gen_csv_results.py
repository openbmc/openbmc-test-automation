#!/usr/bin/env python3

r"""
Use robot framework API to extract test result data from output.xml generated
by robot tests. For more information on the Robot Framework API, see
https://robot-framework.readthedocs.io/en/stable/autodoc/robot.result.html
"""

import csv
import datetime
import os
import stat
import sys
from xml.etree import ElementTree

from robot.api import ExecutionResult
from robot.result.visitor import ResultVisitor

# Remove the python library path to restore with local project path later.
SAVE_PATH_0 = sys.path[0]
del sys.path[0]
sys.path.append(os.path.join(os.path.dirname(__file__), "../../lib"))

from gen_arg import *  # NOQA
from gen_print import *  # NOQA
from gen_valid import *  # NOQA

# Restore sys.path[0].
sys.path.insert(0, SAVE_PATH_0)


this_program = sys.argv[0]
info = " For more information:  " + this_program + "  -h"
if len(sys.argv) == 1:
    print(info)
    sys.exit(1)


parser = argparse.ArgumentParser(
    usage=info,
    description=(
        "%(prog)s uses a robot framework API to extract test result    data"
        " from output.xml generated by robot tests. For more information on"
        " the    Robot Framework API, see   "
        " https://robot-framework.readthedocs.io/en/stable/autodoc/robot.result.html"
    ),
    formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    prefix_chars="-+",
)

parser.add_argument(
    "--source",
    "-s",
    help=(
        "The output.xml robot test result file path.  This parameter is "
        "    required."
    ),
)

parser.add_argument(
    "--dest",
    "-d",
    help=(
        "The directory path where the generated .csv files will go.  This"
        " parameter is required."
    ),
)

parser.add_argument(
    "--version_id",
    help=(
        "Driver version of openbmc firmware which was used during test,"
        '   e.g. "v2.1-215-g6e7eacb".  This parameter is required.'
    ),
)

parser.add_argument(
    "--platform",
    help=(
        "OpenBMC platform which was used during test, e.g."
        ' "Witherspoon".  This parameter is required.'
    ),
)

parser.add_argument(
    "--level",
    help=(
        "OpenBMC release level which was used during test, e.g."
        ' "Master", "OBMC920".  This parameter is required.'
    ),
)

parser.add_argument(
    "--test_phase",
    help=(
        'Name of testing phase, e.g. "CI", "Regression", etc. This'
        " parameter is optional."
    ),
    default="FVT",
)

parser.add_argument(
    "--subsystem",
    help=(
        'Name of the subsystem, e.g. "OPENBMC" etc. This parameter is'
        " optional."
    ),
    default="OPENBMC",
)

parser.add_argument(
    "--processor",
    help='Name of processor, e.g. "XY". This parameter is optional.',
    default="OPENPOWER",
)


# Populate stock_list with options we want.
stock_list = [("test_mode", 0), ("quiet", 0), ("debug", 0)]


def exit_function(signal_number=0):
    r"""
    Execute whenever the program ends normally or with the signals that we
    catch (i.e. TERM, INT).
    """

    dprint_executing()

    dprint_var(signal_number)

    qprint_pgm_footer()


def signal_handler():
    r"""
    Handle signals.  Without a function to catch a SIGTERM or SIGINT, the
    program would terminate immediately with return code 143 and without
    calling the exit_function.
    """

    # Our convention is to set up exit_function with atexit.register() so
    # there is no need to explicitly call exit_function from here.

    dprint_executing()

    # Calling exit prevents us from returning to the code that was running
    # when the signal was received.
    sys.exit(0)


def validate_parms():
    r"""
    Validate program parameters, etc.  Return True or False (i.e. pass/fail)
    accordingly.
    """

    if not valid_file_path(source):
        return False

    if not valid_dir_path(dest):
        return False

    gen_post_validation(exit_function, signal_handler)

    return True


def parse_output_xml(
    xml_file_path,
    csv_dir_path,
    version_id,
    platform,
    level,
    test_phase,
    processor,
):
    r"""
    Parse the robot-generated output.xml file and extract various test
    output data. Put the extracted information into a csv file in the "dest"
    folder.

    Description of argument(s):
    xml_file_path                   The path to a Robot-generated output.xml
                                    file.
    csv_dir_path                    The path to the directory that is to
                                    contain the .csv files generated by
                                    this function.
    version_id                      Version of the openbmc firmware
                                    (e.g. "v2.1-215-g6e7eacb").
    platform                        Platform of the openbmc system.
    level                           Release level of the OpenBMC system
                                    (e.g. "Master").
    test_phase                      Name of the test phase
                                    e.g. "CI", "Regression", etc.
    processor                       Name of processor, e.g. "XY".
    """

    # Initialize tallies
    total_critical_tc = 0
    total_critical_passed = 0
    total_critical_failed = 0
    total_non_critical_tc = 0
    total_non_critical_passed = 0
    total_non_critical_failed = 0

    result = ExecutionResult(xml_file_path)
    result.configure(
        stat_config={
            "suite_stat_level": 2,
            "tag_stat_combine": "tagANDanother",
        }
    )

    stats = result.statistics
    print("--------------------------------------")
    try:
        total_critical_tc = (
            stats.total.critical.passed + stats.total.critical.failed
        )
        total_critical_passed = stats.total.critical.passed
        total_critical_failed = stats.total.critical.failed
    except AttributeError:
        pass

    try:
        total_non_critical_tc = stats.total.passed + stats.total.failed
        total_non_critical_passed = stats.total.passed
        total_non_critical_failed = stats.total.failed
    except AttributeError:
        pass

    print(
        "Total Test Count:\t %d" % (total_non_critical_tc + total_critical_tc)
    )

    print("Total Critical Test Failed:\t %d" % total_critical_failed)
    print("Total Critical Test Passed:\t %d" % total_critical_passed)
    print("Total Non-Critical Test Failed:\t %d" % total_non_critical_failed)
    print("Total Non-Critical Test Passed:\t %d" % total_non_critical_passed)
    print("Test Start Time:\t %s" % result.suite.starttime)
    print("Test End Time:\t\t %s" % result.suite.endtime)
    print("--------------------------------------")

    # Use ResultVisitor object and save off the test data info.
    class TestResult(ResultVisitor):
        r"""
        Class methods to save off the test data information.
        """

        def __init__(self):
            self.test_data = []

        def visit_test(self, test):
            self.test_data += [test]

    collect_data_obj = TestResult()
    result.visit(collect_data_obj)

    # Write the result statistics attributes to CSV file
    l_csvlist = []

    # Default Test data
    l_test_type = test_phase

    l_pse_rel = "Master"
    if level:
        l_pse_rel = level

    l_env = "HW"
    l_proc = processor
    l_platform_type = ""
    l_func_area = ""

    # System data from XML meta data
    # l_system_info = get_system_details(xml_file_path)

    # First let us try to collect information from keyboard input
    # If keyboard input cannot give both information, then find from xml file.
    if version_id and platform:
        l_driver = version_id
        l_platform_type = platform
        print("BMC Version_id:%s" % version_id)
        print("BMC Platform:%s" % platform)
    else:
        # System data from XML meta data
        l_system_info = get_system_details(xml_file_path)
        l_driver = l_system_info[0]
        l_platform_type = l_system_info[1]

    # Driver version id and platform are mandatorily required for CSV file
    # generation. If any one is not avaulable, exit CSV file generation
    # process.
    if l_driver and l_platform_type:
        print("Driver and system info set.")
    else:
        print(
            "Both driver and system info need to be set.                CSV"
            " file is not generated."
        )
        sys.exit()

    # Default header
    l_header = [
        "test_start",
        "test_end",
        "subsys",
        "test_type",
        "test_result",
        "test_name",
        "pse_rel",
        "driver",
        "env",
        "proc",
        "platform_type",
        "test_func_area",
    ]

    l_csvlist.append(l_header)

    # Generate CSV file onto the path with current time stamp
    l_base_dir = csv_dir_path
    l_timestamp = datetime.datetime.utcnow().strftime("%Y-%m-%d-%H-%M-%S")
    # Example: 2017-02-20-08-47-22_Witherspoon.csv
    l_csvfile = l_base_dir + l_timestamp + "_" + l_platform_type + ".csv"

    print("Writing data into csv file:%s" % l_csvfile)

    for testcase in collect_data_obj.test_data:
        # Functional Area: Suite Name
        # Test Name: Test Case Name
        l_func_area = str(testcase.parent).split(" ", 1)[1]
        l_test_name = str(testcase)

        # Test Result pass=0 fail=1
        if testcase.status == "PASS":
            l_test_result = 0
        elif testcase.status == "SKIP":
            # Skipped test result should not be mark pass or fail.
            continue
        else:
            l_test_result = 1

        # Format datetime from robot output.xml to "%Y-%m-%d-%H-%M-%S"
        l_stime = xml_to_csv_time(testcase.starttime)
        l_etime = xml_to_csv_time(testcase.endtime)
        # Data Sequence: test_start,test_end,subsys,test_type,
        #                test_result,test_name,pse_rel,driver,
        #                env,proc,platform_type,test_func_area,
        l_data = [
            l_stime,
            l_etime,
            subsystem,
            l_test_type,
            l_test_result,
            l_test_name,
            l_pse_rel,
            l_driver,
            l_env,
            l_proc,
            l_platform_type,
            l_func_area,
        ]
        l_csvlist.append(l_data)

    # Open the file and write to the CSV file
    with open(l_csvfile, "w", encoding="utf8") as l_file:
        l_writer = csv.writer(l_file, lineterminator="\n")
        l_writer.writerows(l_csvlist)
        l_file.close()

    # Set file permissions 666.
    perm = (
        stat.S_IRUSR
        + stat.S_IWUSR
        + stat.S_IRGRP
        + stat.S_IWGRP
        + stat.S_IROTH
        + stat.S_IWOTH
    )
    os.chmod(l_csvfile, perm)


def xml_to_csv_time(xml_datetime):
    r"""
    Convert the time from %Y%m%d %H:%M:%S.%f format to %Y-%m-%d-%H-%M-%S format
    and return it.

    Description of argument(s):
    xml_datetime                        The date in the following format: %Y%m%d
                                    %H:%M:%S.%f (This is the format
                                    typically found in an XML file.)

    The date returned will be in the following format: %Y-%m-%d-%H-%M-%S
    """

    # 20170206 05:05:19.342
    l_str = datetime.datetime.strptime(xml_datetime, "%Y%m%d %H:%M:%S.%f")
    # 2017-02-06-05-05-19
    l_str = l_str.strftime("%Y-%m-%d-%H-%M-%S")
    return str(l_str)


def get_system_details(xml_file_path):
    r"""
    Get the system data from output.xml generated by robot and return it.
    The list returned will be in the following order: [driver,platform]

    Description of argument(s):
    xml_file_path                   The relative or absolute path to the
                                    output.xml file.
    """

    bmc_version_id = ""
    bmc_platform = ""
    with open(xml_file_path, "rt", encoding="utf-8") as output:
        tree = ElementTree.parse(output)

    for node in tree.iter("msg"):
        # /etc/os-release output is logged in the XML as msg
        # Example: ${output} = VERSION_ID="v1.99.2-71-gbc49f79"
        if "${output} = VERSION_ID=" in node.text:
            # Get BMC version (e.g. v1.99.1-96-g2a46570)
            bmc_version_id = str(node.text.split("VERSION_ID=")[1])[1:-1]

        # Platform is logged in the XML as msg.
        # Example: ${bmc_model} = Witherspoon BMC
        if "${bmc_model} = " in node.text:
            bmc_platform = node.text.split(" = ")[1]

    print_vars(bmc_version_id, bmc_platform)
    return [str(bmc_version_id), str(bmc_platform)]


def main():
    r"""
    Main caller.
    """

    if not gen_get_options(parser, stock_list):
        return False

    if not validate_parms():
        return False

    qprint_pgm_header()

    parse_output_xml(
        source, dest, version_id, platform, level, test_phase, processor
    )

    return True


# Main

if not main():
    sys.exit(1)
