#!/usr/bin/env python

import gen_print as gp
import gen_cmd as gc
import collections

module_names = ['Selenium2Library', 'SeleniumLibrary', 'SSHLibrary', 'requests',
                'XvfbRobot', 'robotremoteserver', 'redfish']

import_versions = collections.OrderedDict()

for module_name in module_names:
    try:
        cmd_buf = "import " + module_name
        exec(cmd_buf)
        cmd_buf = "import_versions['" + module_name + "'] = " + module_name \
                  + ".__version__"
        exec(cmd_buf)
    except ImportError:
        import_versions[module_name] = "Not installed"


def software_versions():
    r"""
    Get the versions for several of the software packages used by
    openbmc-test-automation and return as a dictionary.

    Example call:
    ${software_versions}=  Software Versions
    Rprint Vars  software_versions

    Example output:
    software_versions:
      [python]:                                       Python 2.7.12
      [robot]:                                        Robot Framework 3.1.2 (Python 3.6.8 on linux)
      [firefox]:                                      Mozilla Firefox 54.0
      [google-chrome]:                                Not installed
      [Selenium2Library]:                             3.0.0
      [SeleniumLibrary]:                              3.3.1
      [SSHLibrary]:                                   3.3.0
      [requests]:                                     2.22.0
      [XvfbRobot]:                                    1.2.2
      [robotremoteserver]:                            1.1
      [redfish]:                                      2.1.1
      [robotframework-angularjs]:                     0.0.10
      [robotframework-scplibrary]:                    1.2.0
      [robotframework-extendedselenium2library]:      0.9.1
      [host OS]:                                      Ubuntu 16.04.6 LTS
    """

    quiet = 1
    versions = collections.OrderedDict()
    for package in ['python', 'python3', 'robot', 'firefox', 'google-chrome']:
        # Note: "robot --version" returns 0x00000000000000fb.
        # Note: If package does not exist, 0x7f is returned.
        rc, version = gc.shell_cmd(package + " --version",
                                   valid_rcs=[0, 0x7f, 0xfb])
        versions[package] = "Not installed" if rc == 0x7f else version.rstrip('\n')

    versions.update(import_versions)

    for package in ['robotframework-angularjs', 'robotframework-scplibrary',
                    'robotframework-extendedselenium2library']:
        rc, version = gc.shell_cmd("pip3 show " + package
                                   + " | grep Version | sed -re 's/.*: //g'")
        versions[package] = "Not installed" if not version else version.rstrip('\n')

    rc, version = gc.shell_cmd("lsb_release -d -s")
    versions["host OS"] = "Failed" if not version else version.rstrip('\n')
    return versions
