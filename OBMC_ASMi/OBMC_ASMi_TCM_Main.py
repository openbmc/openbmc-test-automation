#!/usr/bin/python


r'''
Exports issues from a list of repositories to individual CSV files.
Uses basic authentication (GitHub username + password) to retrieve issues
from a repository that username has access to. Supports GitHub API v3.
'''

import sys
import os
import getopt
import datetime
import string
import time
import random
import socket
import subprocess

#---------Set sys.path for OBMC_ASMi execution---------------------------------------

def usage():
    print "Usage: %s   <one or more parameters>"  % os.path.basename(__file__)
    print "  Used to initiate test cases on a target machine."
    print "  Parameters:"
    print "     -F | --function        function_name "
    print "     -T | --testcase        testcase_name "
    print "     -S | --stopatfailure   Stop at failure"

def main(argv):
    # scl command to enable python27
    l_scl_cmd_python27 = "scl enable python27 bash;"

    # OpneBMC_ASMi path
    OBMC_asmipath = "openbmc-test-automation"
    l_chdir_cmd = "cd " + OBMC_asmipath + ";"

    # python27 user path
    l_python_cmd_prefix = "/opt/rh/python27/root/usr/bin/"
    l_Result = "OBMC_GUI_OutputResult"

    l_Test_Function = None
    l_obmc_asmi_tc = None
    l_outputresult = None
    l_stop_at_failure = ""
    l_enable_python_ver_cmd = None
    l_obmc_asmi_rf_command = None

    if len(sys.argv) == 1:
        usage()
        sys.exit()
    try:
        opts, args = getopt.getopt(
            argv, "hF:T:M:SR", [
                "help", "function=", "testcase=", "stopatfailure"])

    except getopt.GetoptError:
        usage()
        sys.exit()


    for opt, arg in opts:
        if opt in ("-h", "--help"):
            usage()
            sys.exit()
        elif opt in ("-F", "--function"):
            l_Test_Function = arg
        elif opt in ("-T", "--testcase"):
            l_Test_Case = arg
        elif opt in ("-S", "--stopatfailure"):
            l_stop_at_failure = True


    if(not(l_Test_Function) == None):
        m_TestCase = [l_Test_Function]

    for i in m_TestCase:
        i == "OBMC_ASMi"
        print "\n\nTest Case Name:" + l_Test_Case
        l_obmc_asmi_tc = l_Test_Case

        # Enabling Stop At Failure in RF

        if  (l_stop_at_failure == True):
            l_obmc_asmi_stop_at_failure = "--exitonfailure"
        else:
            l_obmc_asmi_stop_at_failure = ""


    starttime = datetime.datetime.now()

    try:
        # Robot Framework Command
        l_obmc_asmi_rf_command = l_python_cmd_prefix + "python -m robot "\
        + str('-i ') + str(l_Test_Case) + " " \
        + str(l_obmc_asmi_stop_at_failure) \
        + " -N OpenBMC_ASMi --dotted --outputdir " \
        + str(l_Result) + " " + str(l_Test_Function)

        l_rc = subprocess.check_call(l_scl_cmd_python27 \
               + l_chdir_cmd + l_obmc_asmi_rf_command, shell=True)

    except subprocess.CalledProcessError as e:
        print "Failure from Robot Framework for the command:" \
                                     + l_obmc_asmi_rf_command
        l_rc = e.returncode

    finally:
        endtime = datetime.datetime.now()
        print "\nTest Case Execution End Time: " + str(endtime)
        print "Total Test Execution Time for this Test Case Execution: " \
                     + str((endtime - starttime).seconds) + " seconds\n"

        print "\nAm Exiting...\n"

        if(l_rc == 0):
            print 'Test Passed'
            sys.exit(l_rc)
        else:
            print 'Test Failed'
            sys.exit(l_rc)


if __name__ == "__main__":
    main(sys.argv[1:])
