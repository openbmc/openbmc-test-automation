#!/usr/bin/env python

r"""
Module for HMC related methods.
"""

import sys
import time
sys.path.insert(1, 'lib')
import gen_robot_ssh as grs
import gen_valid as gv
import gen_misc as gm
from robot.libraries.BuiltIn import BuiltIn


class hmc_utils():
    r"""
    Base class for HMC related methods.
    """

    def __init__(self, bmc_name, hmc_name, bmc_user, bmc_pwd):
        r"""
        Base initialization method.
        """
        self.__bmc = bmc_name
        self.__hmc = hmc_name
        _, self.__bmc_ip = gm.get_host_name_ip(self.__bmc)

        self.__bmc_user = bmc_user
        self.__bmc_pwd = bmc_pwd

        self.__credentials = {'hscroot': 'abc123',
                              'hscpe': 'abcd1234',
                              'sudo_pwd': 'abcd1234'
                              }

        self.__login_params = {'hscroot': (':~> ', 'hmc_connection_' + hmc_name,),
                               'hscpe': ('$ ', 'pe_connection_' + hmc_name,),
                               'sudo': ('$ ', 'sudo_hmc_connection_' + hmc_name,)
                               }

    def hmc_execute_cmd(self, cmd, hmc_user='hscroot', pwd=None, sudo=False,
                        sudo_passwd=None, connection_name=None, prompt=None):
        r"""
        Execute commands on HMC and return output.
        Description of arguments:
        cmd                Command to be executed.
        hmc_user           HMC login user.
        pwd                Login password.
        sudo               Sudo login.
        sudo_passwd        Sudo password.
        connection_name    Connection name.
        prompt             HMC CLI prompt.
        """

        if sudo:
            BuiltIn().log("Logging in to HMC as hscpe by default")

            prompt = prompt or self.__login_params['sudo'][0]
            alias = connection_name or self.__login_params['sudo'][1]
            open_connection_args = {'host': self.__hmc, 'alias': alias,
                                    'timeout': '25.0', 'prompt': prompt}
            login_args = {'username': 'hscpe', 'password': self.__credentials['hscpe']}

            stdout, stderr, rc = grs.execute_ssh_command(cmd, open_connection_args,
                                                         login_args, sudo=True,
                                                         sudo_pwd=self.__credentials['sudo_pwd'])
        else:
            prompt = prompt or self.__login_params[hmc_user][0]
            alias = connection_name or self.__login_params[hmc_user][1]
            open_connection_args = {'host': self.__hmc, 'alias': alias,
                                    'timeout': '25.0', 'prompt': prompt}
            login_args = {'username': hmc_user, 'password': self.__credentials[hmc_user]}

            stdout, stderr, rc = grs.execute_ssh_command(cmd, open_connection_args,
                                                         login_args)
        return stdout, stderr, rc

    def connect_cec(self):
        r"""
        Connect CEC to HMC.
        """

        connect_cec_cmd = "mksysconn --ip " + self.__bmc_ip + " -r sys -u " + \
                          self.__bmc_user + " --passwd " + self.__bmc_pwd
        stdout, stderr, rc = self.hmc_execute_cmd(connect_cec_cmd)
        return stdout, stderr, rc

    def disconnect_cec(self):
        r"""
        Remove CEC from HMC.
        """

        remove_cec_cmd = "rmsysconn -o remove --ip " + self.__bmc_ip
        stdout, stderr, rc = self.hmc_execute_cmd(remove_cec_cmd)
        return stdout, stderr, rc

    def get_hmc_events(self, search_key):
        r"""
        Get events from HMC.
        """

        event_lookup_cmd = "cat /var/hsc/log/cimserver.log|grep -a 'Redfish Event received from " + \
        self.__bmc_ip + "'" + ">/tmp/events.txt;sed -n '/" + search_key + "/,/" + search_key + "/p' /tmp/events.txt"

        stdout, stderr, rc = self.hmc_execute_cmd(event_lookup_cmd, sudo=True)
        BuiltIn().log(stdout)
        if rc:
            raise Exception("No events found")
        elif stdout.count(search_key) < 2:
            raise Exception("All events not found")
        return stdout, stderr, rc

    def get_cec_state(self):
        r"""
        Get CEC state in HMC.
        """

        get_cec_state_cmd = "lssyscfg -r sys -F ipaddr,state|grep " + self.__bmc_ip
        stdout, stderr, rc = self.hmc_execute_cmd(get_cec_state_cmd)
        return stdout, stderr, rc

    def get_system_name(self):
       r"""
       Get system name in HMC.
       """

       get_system_name_cmd = "lssyscfg -r sys -F name,ipaddr |grep " + self.__bmc_ip
       stdout, stderr, rc = self.hmc_execute_cmd(get_system_name_cmd)
       sys_name = stdout.split(',')[0]
       return sys_name

    def create_resource_dump(self,resource_identifier):
        r"""
        Creates a resource dump for a given resource identifier from HMC.
        """

        system_name = self.get_system_name()
        start_resource_dump_cmd = "startdump -t resource -m " + system_name +" -r " + resource_identifier
        stdout, stderr, rc = self.hmc_execute_cmd(start_resource_dump_cmd)
        return stdout, stderr, rc

    def verify_resource_dump_offload(self):
       r"""
       Verify resource dump offload in HMC.
       """

       system_name = self.get_system_name()
       wait_loop = 50
       for wait_count_loop in range(wait_loop):
           time.sleep(5)
           get_dump_offload_status_cmd = "lsdump -m " + system_name
           stdout, stderr, rc = self.hmc_execute_cmd(get_dump_offload_status_cmd)
           print(stdout)
           if "dump_type=resource" in stdout:
               # returns from function when dump is not offloaded within specified time.
               if wait_count_loop == (wait_loop-1):
                   print("Failed to offload dump within specified time.Please check manually.")
                   return
               continue
           else:
               time.sleep(5)
               offloaded_dump_file_verify_cmd = r"ls -l /dump | grep RSCDUMP"
               stdout, stderr, rc = self.hmc_execute_cmd(offloaded_dump_file_verify_cmd)
               offloaded_dump_size = stdout.split()[4]
               break

       return offloaded_dump_size


    def verify_system_dump_offload(self, file_name):
       r"""
       Verify system dump offload in HMC.
       """

       system_name = self.get_system_name()
       BuiltIn().log("System_name:" + system_name)
       wait_loop = 50
       for wait_count_loop in range(wait_loop):
           time.sleep(5)
           get_dump_offload_status_cmd = "lsdump -m " + system_name
           stdout, stderr, rc = self.hmc_execute_cmd(get_dump_offload_status_cmd)
           BuiltIn().log(stdout)
           BuiltIn().log(stderr)
           print(stdout)
           if "dump_type=sys" in stdout:
               # returns from function when dump is not offloaded within specified time.
               if wait_count_loop == (wait_loop-1):
                   print("Failed to offload dump within specified time.Please check manually.")
                   return
               continue
           else:
               time.sleep(5)
               offloaded_dump_file_verify_cmd = r"ls -l /dump | grep " + file_name
               stdout, stderr, rc = self.hmc_execute_cmd(offloaded_dump_file_verify_cmd)
               BuiltIn().log(stdout)
               BuiltIn().log(stderr)
               print(stdout)
               offloaded_dump_size = stdout.split()[4]
               BuiltIn().log("offloaded_dump_size: " + offloaded_dump_size)
               break

       return offloaded_dump_size



    def remove_dump_files(self):
       r"""
       Removes dump files in HMC.
       """

       dump_clear_cmd = "rm -f /dump/RSC* /dump/BMC*"
       stdout, stderr, rc = self.hmc_execute_cmd(dump_clear_cmd,sudo=True)
       return stdout, stderr, rc

    def recover_cec(self):
        r"""
        Recover CEC.
        """
        get_sys_name_cmd = "lssyscfg -r sys -F ipaddr, name|grep " + self.__bmc_ip
        stdout, stderr, rc = self.hmc_execute_cmd(get_sys_name_cmd)
        sys_name = stdout.split(",")[-1]

        recover_cec_cmd = "chsysstate -m " + sys_name + " -r sys -o recover"
        stdout, stderr, rc = self.hmc_execute_cmd(recover_cec_cmd)
        if rc:
            BuiltIn().log(stdout)
            BuiltIn().log(stderr)
            raise Exception("Could not recover CEC")

    def get_primary_hmc_ip(self):
       r"""
       Get primary HMC IP.
       Example output:

       is_primary=1,primary_hmc_mtms=<primary_hmc_mtms>,primary_hmc_ipaddr=<hmc_ip>,
       primary_hmc_hostname=<hmc_hostname>,primary_hmc_ipv6addr=

       Function returns hmc_ip.

       """
       system_name = self.get_system_name()
       get_primary_hmc_cmd = "lsprimhmc -m "+ system_name
       stdout, stderr, rc = self.hmc_execute_cmd(get_primary_hmc_cmd)
       primary_hmc = stdout.split(',')[2]
       primary_hmc_ip = primary_hmc.split('=')[1]
       return primary_hmc_ip
