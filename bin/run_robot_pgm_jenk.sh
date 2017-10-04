#!/bin/bash

# Run an obmc test robot program in a docker environment.

# This program is to be run from a Jenkins job such as 'Run-Robot-Program'.
# This program expects the Jenkins job to provide several parameter values
# as environment variables.  This includes but is not limited to the
# following:
# WORKSPACE
# robot_file_path
# git_dir_path
# post_clone_command
# openbmc_host
# openbmc_username
# openbmc_password
# additional_parms

# Source other bash files containing required functions.
source_files="jenkins_funcs.sh"
pathlist=$(/usr/bin/which $source_files) || exit 1
for filepath in $pathlist ; do source $filepath || exit 1 ; done

# Fail if an unset variable is accessed.
set -u

# Assign default values.
WORKSPACE="${WORKSPACE:-${HOME}}"
git_dir_path="${git_dir_path:-${WORKSPACE}}"

# Follow the convention of ensuring that dir paths end with slash.
WORKSPACE="${WORKSPACE%/}/"
git_dir_path="${git_dir_path%/}/"


function mainf {

  # Delete leftover output from prior runs.
  rm -f ${WORKSPACE}*.html ${WORKSPACE}*.xml || return 1
  process_git "${git_dir_path}" "${post_clone_command-}" || return 1
  process_docker "${git_dir_path}" || return 1

  if [ -z "${robot_file_path-}" ] ; then
    echo "robot_file_path is blank so no there is no need to continue."
    return
  fi

  run_docker_robot "${robot_file_path}" || return 1

}


# Main

  mainf "${@}"
  rc="${?}"
  exit "${rc}"
