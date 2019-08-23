#!/usr/bin/python

import gen_print as gp
import gen_cmd as gc
import collections
try:
    import Selenium2Library
    selenium_2_version = Selenium2Library.__version__
except ImportError:
    selenium_2_version = "Not installed"
try:
    import SeleniumLibrary
    selenium_version = SeleniumLibrary.__version__
except ImportError:
    selenium_version = "Not installed"
try:
    import SSHLibrary
    ssh_lib_version = SSHLibrary.__version__
except ImportError:
    ssh_lib_version = "Not installed"
try:
    import requests
    requests_version = requests.__version__
except ImportError:
    requests_version = "Not installed"
try:
    import XvfbRobot
    xvfb_version = XvfbRobot.__version__
except ImportError:
    xvfb_version = "Not installed"
try:
    import robotremoteserver
    remote_version = robotremoteserver.__version__
except ImportError:
    remote_version = "Not installed"
try:
    import redfish
    redfish_version = redfish.__version__
except ImportError:
    redfish_version = "Not installed"


def software_versions():
    r"""
    Get the versions for several of the software packages used by
    openbmc-test-automation and return as a dictionary.

    Example call:
    ${software_versions}=  Software Versions
    Rprint Vars  software_versions

    Example output:
    software_versions:
      [python]:                  Python 2.7.13
      [robot]:                   Robot Framework 3.1.2 (Python 2.7.13 on linux2)
      [firefox]:                 Mozilla Firefox 60.7.2
      [selenium]:                Not installed
    """

    quiet = 1
    versions = collections.OrderedDict()
    for package in ['python', 'robot', 'firefox', 'google-chrome']:
        # Note: "robot --version" returns 0x00000000000000fb.
        rc, version = gc.shell_cmd(package + " --version",
                                   allowed_shell_rcs=[0, 0x00000000000000fb])
        if version.__contains__("command not found"):
            versions[package] = "Not installed"
        else:
            versions[package] = version.rstrip('\n')

    versions['robotframework-selenium2library'] = selenium_2_version
    versions['robotframework-seleniumlibrary'] = selenium_version
    versions['robotframework-requests'] = requests_version
    versions['robotframework-xvfb'] = xvfb_version
    versions['robotremoteserver'] = remote_version
    versions['redfish'] = redfish_version

    for package in ['robotframework-angularjs', 'robotframework-scplibrary',
                    'robotframework-extendedselenium2library']:
        rc, version = gc.shell_cmd("pip show " + package + "|grep Version",
                                   allowed_shell_rcs=[0])
        if not(version):
            versions[package] = "Not installed"
        else:
            versions[package] = version.rstrip('\n').split("Version: ")[1]

    rc, version = gc.shell_cmd("cat /etc/os-release|grep VERSION=",
                               allowed_shell_rcs=[0])
    versions["host OS"] = version.rstrip('\n').split("VERSION=")[1]
    return versions


if __name__ == "__main__":
    print(software_versions())
