#!/usr/bin/env python

r"""
Network generic functions.

"""

import re
import ipaddress
from robot.libraries.BuiltIn import BuiltIn
import var_funcs as vf


def netmask_prefix_length(netmask):
    r"""
    Return the netmask prefix length.

    Description of argument(s):
    netmask     Netmask value (e.g. "255.255.0.0", "255.255.255.0",
                                    "255.252.0.0", etc.).
    """

    # IP address netmask format: '0.0.0.0/255.255.252.0'
    return ipaddress.ip_network('0.0.0.0/' + netmask).prefixlen


def parse_nping_output(output):
    r"""
    Parse the output from the nping command and return as a dictionary.

    Example of output value:

    Starting Nping 0.6.47 ( http://nmap.org/nping ) at 2019-08-07 22:05 IST
    SENT (0.0181s) TCP Source IP:37577 >
      Destination IP:80 S ttl=64 id=39113 iplen=40  seq=629782493 win=1480
    SENT (0.2189s) TCP Source IP:37577 >
      Destination IP:80 S ttl=64 id=39113 iplen=40  seq=629782493 win=1480
    RCVD (0.4120s) TCP Destination IP:80 >
      Source IP:37577 SA ttl=49 id=0 iplen=44  seq=1078301364 win=5840 <mss 1380>
    Max rtt: 193.010ms | Min rtt: 193.010ms | Avg rtt: 193.010ms
    Raw packets sent: 2 (80B) | Rcvd: 1 (46B) | Lost: 1 (50.00%)
    Nping done: 1 IP address pinged in 0.43 seconds

    Example of output:

    nping_result:
      [max_rtt]:                 193.010ms
      [min_rtt]:                 193.010ms
      [avg_rtt]:                 193.010ms
      [raw_packets_sent]:        2 (80B)
      [rcvd]:                    1 (46B)
      [lost]:                    1 (50.00%)
      [percent_lost]:            50.00

    Description of argument(s):
    output                          The output obtained by running an nping
                                    command.
    """

    lines = output.split("\n")
    # Obtain only the lines of interest.
    lines = list(filter(lambda x: re.match(r"(Max rtt|Raw packets)", x),
                        lines))

    key_value_list = []
    for line in lines:
        key_value_list += line.split("|")
    nping_result = vf.key_value_list_to_dict(key_value_list)
    # Extract percent_lost value from lost field.
    nping_result['percent_lost'] = \
        float(nping_result['lost'].split(" ")[-1].strip("()%"))
    return nping_result
