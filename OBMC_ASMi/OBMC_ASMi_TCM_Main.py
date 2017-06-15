#!/usr/bin/python

##
#    @file      OBMC_ASMi_TCM_Main.py
#    @brief     Test Case Module (TCM) Main driver for
#               Open BMC GUI Auto-Test framework
#
#    @author    Sathyajith M.S.
#
#    @date      June 06, 2017
#
#    @param     hF:T:C:M:SR
#    @param     ["function=","testcase=","stopatfailure","startstoptrace"]
##

import sys
import os
import getopt
import datetime
import string
import time
import random
import socket
import subprocess

#---------Set sys.path for pcat execution---------------------------------------
def __init__(self):
    #self.LogMgr = FWLogManager()
    #self.Logger = self.LogMgr.GetAppLogger('Pre-setup Logs')
    #self.pcatpath = cwd1.split('pcat')[0]
    self.OBMC_asmipath = self.pcatpath + "OBMC_ASMi/"
    pass

def main(argv):
    l_Stop_At_Failure = False
    l_Test_Function = None
    l_Test_Case = None
    l_testarray = []

    l_execute = None
    l_env = None

    #Used for ASMI
    l_asmi_tc   = None
    l_outputresult = None
    l_asmi_stop_at_failure  = ""
    l_enable_python_ver_cmd = None
    l_asmi_rf_command = None

    if len(sys.argv) == 1:
        usage()
        sys.exit()
    try:
        opts, args = getopt.getopt(
            argv, "hF:T:C:M:SR", [
                "help", "function=", "testcase=", "config=", "machine=",
                 "stopatfailure", "startstoptrace"])

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
            l_Stop_At_Failure = True


    if(not(l_Test_Function) == None):
        m_TestCase = [l_Test_Function]

    for i in m_TestCase:
    # for asmi robot framework
        if i == "OBMC_asmi":
            print "test case number:" + l_Test_Case

            #for priority1 tcs run
            if (l_Test_Case == "P1"):
                l_asmi_tc = "-i p1"

             #for priority1 tcs run
            elif (l_Test_Case == "P2"):
                l_asmi_tc = "-i p2"

             #for priority1 tcs run
            elif (l_Test_Case == "P3"):
                l_asmi_tc = "-i p3"

            #for all tcs run
            elif (l_Test_Case == "ALL"):
                l_asmi_tc = ""

            #for standby tcs run
            elif (l_Test_Case == "S"):
                l_asmi_tc = "-i standby"

            #for runtime tcs run
            elif (l_Test_Case == "R"):
                l_asmi_tc = "-i runtime"

            #for Simics tcs run
            #elif (l_Test_Case == "888"):
            #    l_asmi_tc = "-e disable"

            #for a single testcase run
            else:
                l_testprefix = "-t test#"
                l_asmi_tc = l_testprefix + str(l_Test_Case)

            # enabling Stop At Failure in RF
            if  (l_Stop_At_Failure == True):
                l_asmi_stop_at_failure = "--exitonfailure"
            else:
                l_asmi_stop_at_failure  = ""


    starttime = datetime.datetime.now()

    if l_Test_Function=="OBMC_asmi":

        # scl command to enable python27
        l_scl_cmd_python27 = "scl enable python27 bash;"

        # ASMI path
        l_chdir_cmd = "cd " + self.OBMC_asmipath + ";"

        # python27 user path
        l_python_cmd_prefix = "/opt/rh/python27/root/usr/bin/"

        # Robot Framework Command

        l_status = False
        if i_asmi_tc=="":
            l_TCExecutionOrder = [ 'standby', 'runtime' ]
            for l_TCExectuonSelection in l_TCExecutionOrder:

                l_tmp = i_outputresult + '_' + l_TCExectuonSelection
                l_asmi_rf_command = l_python_cmd_prefix + "python -m robot "\
                + str('-i ') + str(l_TCExectuonSelection) + " " + str(i_asmi_stop_at_failure) + \
                " -N ASMI --dotted --variable CF:" + str(i_configfile_asmi) + \
                " --outputdir " + str(l_tmp) + " " + str(i_Test_Function)

                subprocess.check_call(l_scl_cmd_python27 + l_chdir_cmd + l_asmi_rf_command, \
                                                                        shell=True)
            # If Standby Test Case failed but Runtime passed, we still need
            # to consider as a failure since this test set is run as a combo
            # of Standby plus Runtime.
            else:
                l_asmi_rf_command = l_python_cmd_prefix + "python -m robot "\
                + str(i_asmi_tc) + " " + str(i_asmi_stop_at_failure) + \
                " -N ASMI --dotted --variable CF:" + str(i_configfile_asmi) + \
                " --outputdir " + str(i_outputresult) + " " + str(i_Test_Function)

                subprocess.check_call(l_scl_cmd_python27 + l_chdir_cmd + l_asmi_rf_command, \
                                                            shell=True)

    # for test functions other than asmi
    else:
        l_result = l_execute.RunTestCommandLine(
            l_testarray,
            l_Test_Function,
            l_Test_Case, l_Stop_At_Failure, l_Start_Stop_Trace)


    endtime = datetime.datetime.now()

    print "Test Case Execution End Time: " + str(endtime)
    l_execute.Logger.TestLog(
        "Total Test Execution Time for this Test Case Execution: " + str(
            (endtime - starttime).seconds) + " seconds\n",
        False)



if __name__ == "__main__":
    main(sys.argv[1:])
