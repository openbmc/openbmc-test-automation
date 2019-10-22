#!/bin/bash

# This file contains list-manipulation functions.

# A list is defined here as a string of items separated by some delimiter.  The PATH variable is one such
# example.

if ! test "${default_delim+defined}" ; then
  readonly default_delim=" "
fi

# Performance note:  It is important for these functions to run quickly.  One way to increase their speed is
# to avoid copying function arguments to local variables and to instead use numbered arguments (e.g. ${1},
# {2}, etc.) to access the arguments from inside the functions.  In some trials, this doubled the speed of
# the functions.  The cost of this is that it makes the functions slightly more difficult to read.


function add_list_element {
  # local list_element="${1}"
  # local list_name="${2}"
  # local delim="${3:-${default_delim}}"
  # local position="${4:-back}"

  # Add the list_element to the list named in list_name.

  # Description of argument(s):
  # list_element                    The list element to be added.
  # list_name                       The name of the list to be modified.
  # delim                           The delimiter used to separate list elements.
  # position                        Indicates the position in the list where the new element should be added
  #                                 ("front"/"back").

  if [ -z "${!2}" ] ; then
    # The list is blank. Simply assign it the list_element value and return.
    eval "${2}=\"${1}\""
    return
  fi

  if [ "${4:-back}" == "back" ] ; then
    # Append the list_element to the back of the list and return.
    eval "${2}=\"\${${2}}\${3-${default_delim}}\${1}\""
    return
  fi

  # Append the list_element to the front of the list and return.
  eval "${2}=\"\${1}\${3-${default_delim}}\${${2}}\""

}


function remove_list_element {
  # local list_element="${1}"
  # local list_name="${2}"
  local delim="${3:-${default_delim}}"

  # Remove all occurrences of list_element from the list named in list_name.

  # Description of argument(s):
  # list_element                    The list element to be removed.
  # list_name                       The name of the list to be modified.
  # delim                           The delimiter used to separate list elements.

  local __rle_new_list__="${!2}"

  # Special case: The list contains one element which matches the specified list element:
  if [ "${1}" == "${__rle_new_list__}" ] ; then
    eval ${2}=\"\"
    return
  fi

  # Replace all occurrences of list_element that are bounded by the delimiter on both sides.
  __rle_new_list__="${__rle_new_list__//${delim}${1}${delim}/${delim}}"
  # Replace list_item if it occurs at the beginning of the string and is bounded on the right by the
  # delimiter.
  __rle_new_list__="${__rle_new_list__#${1}${delim}}"
  # Replace list_item if it occurs at the end of the string and is bounded on the left by the delimiter.
  __rle_new_list__="${__rle_new_list__%${delim}${1}}"

  # Set caller's variable to new value.
  eval ${2}=\"\${__rle_new_list__}\"

}


function cleanup_path_slashes {
  local var_name="${1}" ; shift

  # For the variable named in var_name, replace all multiple-slashes with single slashes and strip any
  # trailing slash.

  # Description of argument(s):
  # var_name                        The name of the variable whose contents are to be changed.

  local cmd_buf

  cmd_buf="${var_name}=\$(echo \"\${${var_name}}\" | sed -re 's#[/]+#/#g' -e 's#/\$##g')"
  eval "${cmd_buf}"

}


function remove_path {
  local dir_path="${1}" ; shift
  local path_var="${1:-PATH}" ; shift

  # Remove all occurrences of dir_path from the path variable named in path_var.

  # Note that this function will remove extraneous slashes from the elements of path_var.

  # Description of argument(s):
  # dir_path                        The directory to be removed from the path variable.
  # path_var                        The name of a variable containing directory paths separated by colons.

  cleanup_path_slashes dir_path || return 1
  cleanup_path_slashes ${path_var} || return 1
  remove_list_element "${dir_path}" "${path_var}" : || return 1

}
