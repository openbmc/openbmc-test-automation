#!/usr/bin/env python

r"""
This file contains utilities associated with the host OS.
"""

import sys
import os

#Remove the python library path to restore with local project path later.
save_path_0 = sys.path[0]
del sys.path[0]
sys.path.append(os.path.join(os.path.dirname(__file__), "../lib"))

import bmc_ssh_utils
import var_funcs

# Restore sys.path[0].
sys.path.insert(0, save_path_0)

from robot.libraries.BuiltIn import BuiltIn

def get_os_release_info():
    r"""

    Get os-release info and return it as a dictionary.

    An example of the contents of /etc/os-release:

    NAME="Red Hat Enterprise Linux Server"
    VERSION="7.5 (Maipo)"
    ID="rhel"
    ID_LIKE="fedora"
    VARIANT="Server"
    VARIANT_ID="server"
    VERSION_ID="7.5"
    PRETTY_NAME="Red Hat Enterprise Linux Server 7.5 Beta (Maipo)"
    ANSI_COLOR="0;31"
    CPE_NAME="cpe:/o:redhat:enterprise_linux:7.5:beta:server"
    HOME_URL="https://www.redhat.com/"
    BUG_REPORT_URL="https://bugzilla.redhat.com/"

    REDHAT_BUGZILLA_PRODUCT="Red Hat Enterprise Linux 7"
    REDHAT_BUGZILLA_PRODUCT_VERSION=7.5
    REDHAT_SUPPORT_PRODUCT="Red Hat Enterprise Linux"
    REDHAT_SUPPORT_PRODUCT_VERSION="7.5 Beta"

    For the data shown above, this function will return the following
    dictionary:

    result:
      [name]:                             Red Hat Enterprise Linux Server
      [version]:                          7.5 (Maipo)
      [id]:                               rhel
      [id_like]:                          fedora
      [variant]:                          Server
      [variant_id]:                       server
      [version_id]:                       7.5
      [pretty_name]:                      Red Hat Enterprise Linux Server 7.5 Beta (Maipo)
      [ansi_color]:                       0;31
      [cpe_name]:                         cpe:/o:redhat:enterprise_linux:7.5:beta:server
      [home_url]:                         https://www.redhat.com/
      [bug_report_url]:                   https://bugzilla.redhat.com/
      [redhat_bugzilla_product]:          Red Hat Enterprise Linux 7
      [redhat_bugzilla_product_version]:  7.5
      [redhat_support_product]:           Red Hat Enterprise Linux
      [redhat_support_product_version]:   7.5 Beta
    """

    stdout, stderr, rc =\
        bmc_ssh_utils.os_execute_command("cat /etc/os-release")

    return var_funcs.key_value_outbuf_to_dict(stdout, delim="=", strip='"')
