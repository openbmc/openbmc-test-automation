#!/usr/bin/wish

# This file provides valuable host and IP manipulation procedures such as
# get_host_name_ip, etc.

my_source [list cmd.tcl]


proc get_host_name_ip {host {quiet 1}} {

  # Get the host name, short host name and the IP address and return them as
  # a list.
  # If this procedure is unable to get the requested information, it will
  # print an error message to stderr and return blank values.

  # Description of argument(s):
  # host                            The host name or IP address to be obtained.
  # quiet                           Indicates whether status information
  #                                 should be printed.

  if { ${quiet} } { set print_output 0 } else { set print_output 1 }
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

