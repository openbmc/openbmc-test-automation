#!/usr/bin/wish

# This file provides valuable host and IP manipulation procedures such as
# get_host_name_ip, etc.

my_source [list cmd.tcl data_proc.tcl]


proc get_host_name_ip {host {quiet 1}} {

  # Get the host name, short host name and the IP address and return them as
  # a list.
  # If this procedure is unable to get the requested information, it will
  # print an error message to stderr and return blank values.

  # Example call:
  # lassign [get_host_name_ip $host] host_name short_host_name ip_address

  # Description of argument(s):
  # host                            The host name or IP address to be obtained.
  # quiet                           Indicates whether status information
  #                                 should be printed.

  set print_output [expr !$quiet]
  lassign [cmd_fnc "host $host" "${quiet}" "" "${print_output}"] rc out_buf
  if { $rc != 0 } { return [list "" "" ""]}

  if { [regexp "has address" $out_buf] } {
    # Host is host name.
    # Format of output:
    # hostname.bla.com has address n.n.n.n.
    lassign [split $out_buf " "] host_name fill1 fill2 ip_address
  } elseif { [regexp "domain name pointer" $out_buf] } {
    # Host is IP address.
    # Format of output:
    # n.n.n.n.in-addr.arpa domain name pointer hostname.bla.com.
    set ip_address ${host}
    lassign [split $out_buf " "] fill0 fill1 fill2 fill3 host_name
    set host_name [string trimright $host_name {.}]
  }
  # Create the short name from the host name.
  lassign [split $host_name "."] short_host_name

  return [list ${host_name} ${short_host_name} ${ip_address}]

}


proc get_host_domain {host username password {quiet 1}} {

  # Return the domain name of the host.

  # If this procedure is unable to get the requested information, it will
  # print an error message to stderr and return a blank value.

  # Description of argument(s):
  # host                            The host name or IP address of the system
  #                                 from which the information is to be
  #                                 obtained.
  # username                        The host username.
  # password                        The host password.
  # quiet                           Indicates whether status information
  #                                 should be printed.

  set print_output [expr !$quiet]
  lassign [cmd_fnc \
    "sshpass -p $password ssh -o StrictHostKeyChecking=no -k $username@$host\
    'dnsdomainname'" ${quiet} "" ${print_output}] rc domain
  return $domain

}


proc get_host_name_servers {host username password {quiet 1}} {

  # Return a list of hostname or IP addresses.

  # If this procedure is unable to get the requested information, it will
  # print an error message to stderr and return a blank value.

  # Description of argument(s):
  # host                            The host name or IP address of the system
  #                                 from which the information is to be
  #                                 obtained.
  # username                        The host username.
  # password                        The host password.
  # quiet                           Indicates whether status information
  #                                 should be printed.

  set print_output [expr !$quiet]
  lassign [cmd_fnc "sshpass -p $password ssh -o StrictHostKeyChecking=no -k\
    $username@$host\
    grep -E '^[ ]*nameserver[ ]+' /etc/resolv.conf | awk '{print \$2}'"\
    ${quiet} "" ${print_output}] rc name_servers
  return [split $name_servers "\n"]

}


proc get_host_mac_address {host username password {interface {}} {quiet 1}} {

  # Return the mac address of the host given a specific interface.

  # If "interface" is left blank, it is set to the default interface.

  # If this procedure is unable to get the requested information, it will
  # print an error message to stderr and return a blank value.

  # Description of argument(s):
  # host                            The host name or IP address of the system
  #                                 from which the information is to be
  #                                 obtained.
  # username                        The host username.
  # password                        The host password.
  # interface                       The target interface. Defaults to default
  #                                 interface if not set.
  # quiet                           Indicates whether status information
  #                                 should be printed.

  set print_output [expr !$quiet]
  set_var_default interface [get_host_default_interface $host $username\
    $password $quiet]
  lassign [cmd_fnc "sshpass -p $password ssh -o StrictHostKeyChecking=no -k\
    $username@$host 'cat /sys/class/net/$interface/address'" \
    ${quiet} "" ${print_output}] rc mac_address
  return $mac_address

}


proc get_host_gateway {host username password {quiet 1}} {

  # Return the gateway of the host.

  # If this procedure is unable to get the requested information, it will
  # print an error message to stderr and return a blank value.

  # Description of argument(s):
  # host                            The host name or IP address of the system
  #                                 from which the information is to be
  #                                 obtained.
  # username                        The host username.
  # password                        The host password.
  # quiet                           Indicates whether status information
  #                                 should be printed.

  set print_output [expr !$quiet]
  lassign [cmd_fnc "sshpass -p $password ssh -o StrictHostKeyChecking=no -k\
    $username@$host ip route | grep -i '^default' | awk '{print \$3}'" \
    ${quiet} "" ${print_output}] rc gateway
  return $gateway

}


proc get_host_default_interface {host username password {quiet 1} } {

  # Return the default interface of the host interface.

  # If this procedure is unable to get the requested information, it will
  # print an error message to stderr and return a blank value.

  # Description of argument(s):
  # host                            The host name or IP address of the system
  #                                 from which the information is to be
  #                                 obtained.
  # username                        The host username.
  # password                        The host password.
  # quiet                           Indicates whether status information
  #                                 should be printed.

  set print_output [expr !$quiet]
  lassign [cmd_fnc "sshpass -p $password ssh -o StrictHostKeyChecking=no -k\
    $username@$host ip route | grep -i '^default' | awk '{print \$5}'" \
    ${quiet} "" ${print_output}] rc interface
  return $interface

}


proc get_host_netmask {host username password {interface {}} {quiet 1}} {

  # Return the subnet mask for the host.

  # If this procedure is unable to get the requested information, it will
  # print an error message to stderr and return a blank value.

  # Description of argument(s):
  # host                            The host name or IP address of the system
  #                                 from which the information is to be
  #                                 obtained.
  # username                        The host username.
  # password                        The host password.
  # interface                       The target interface. Defaults to default
  #                                 interface if not set.
  # quiet                           Indicates whether status information
  #                                 should be printed.

  set print_output [expr !$quiet]
  set sshpass_cmd \
    "sshpass -p $password ssh -o StrictHostKeyChecking=no -k $username@$host"
  set_var_default interface [get_host_default_interface $host $username\
    $password $quiet]
  lassign [cmd_fnc \
    "$sshpass_cmd ifconfig $interface | grep -i mask"\
    ${quiet} "" ${print_output}] rc out_buf
  if {[string match *broadcast* $out_buf]} {
    set mask_cmd "ifconfig $interface | grep ask | awk '{print \$4}'"
  } else {
    set mask_cmd "ifconfig $interface | grep ask | cut -d ':' -f 4"
  }
  lassign [cmd_fnc "$sshpass_cmd $mask_cmd" $quiet] rc netmask
  return $netmask

}
