#!/bin/bash

# This file contains bash functions which may be of use to our Jenkins jobs.


function process_git {
  # Do not echo all commands to terminal.
  set +x
  local git_dir_path="${1}" ; shift || :
  local post_clone_command="${1}" ; shift || :

  # Do git processing for this Jenkins job which includes:
  # - Recognizing existing git repo if appropriate.
  # - Cloning git repo.
  # - Running caller's post_clone_command.

  # Description of argument(s):
  # git_dir_path                    The location of the git dir path (e.g.
  #                                 "/home/johndoe/git/").  If the
  #                                 git_dir_path already exists and it was
  #                                 specified explicitly by the user, this
  #                                 function will neither clone the git repo
  #                                 to this path nor run the
  #                                 post_clone_commands, i.e. the indicated
  #                                 git repo will be used as-is.
  # post_clone_command              Any valid bash command to be run after git
  #                                 clone of openbmc-test-automation. Note
  #                                 that this is intended primarily for Open
  #                                 BMC Test code developers who may wish to
  #                                 cherry pick code changes for testing.

  if [ -d "${git_dir_path}" -a "${git_dir_path}" != "${WORKSPACE}" ] ; then
    echo "\"${git_dir_path}\" already exists and is not the standard" \
         "location of \"${WORKSPACE}\" so no git processing is required."
    return
  fi

  # Echo all subsequent commands to terminal.
  set -x
  mkdir -p "${git_dir_path}" || return 1
  cd "${git_dir_path}" || return 1

  echo "Remove old git repo files."
  rm -Rf ./openbmc-build-scripts
  rm -Rf ./openbmc-test-automation

  git clone https://gerrit.openbmc-project.xyz/openbmc/openbmc-build-scripts\
    || return 1
  git clone https://github.com/openbmc/openbmc-test-automation.git || return 1

  if [ ! -z "${post_clone_command}" ] ; then
    cd openbmc-test-automation || return 1
    echo "Run the caller's post clone command."
    eval "${post_clone_command}" || return 1
  fi

}


function process_docker {
  # Do not echo all commands to terminal.
  set +x
  local git_dir_path="${1}" ; shift || :

  # Source the docker script to prepare our environment for calling docker.

  # Description of argument(s):
  # git_dir_path                    The location of the git dir path (e.g.
  #                                 "/home/johndoe/git/") to be used.

  # Set global DOCKER_IMG_NAME.
  DOCKER_IMG_NAME="openbmc/obmc-docker-image"

  echo "Build the docker image required to execute the robot tests."
  # Echo all subsequent commands to terminal.
  set -x
  cd "${git_dir_path}openbmc-build-scripts" || return 1
  . "./scripts/build-qemu-robot-docker.sh" || return 1

  cd "${git_dir_path}" || return 1

}


if ! test "${stock_robot_program_parms+defined}" ; then
  readonly stock_robot_program_parms="openbmc_host openbmc_username"\
" openbmc_password os_host os_username os_password quiet debug test_mode"
  readonly master_robot_gen_parms="console consolecolors outputdir output log"\
" report loglevel include"
fi
function run_docker_robot {
  # Do not echo all commands to terminal.
  set +x
  local robot_file_path="${1}" ; shift || :
  local robot_pgm_parms="${1-}" ; shift || :
  local robot_gen_parms="${1:-${master_robot_gen_parms}}" ; shift || :

  # Compose a robot command string and run it in a docker environment.

  # Description of argument(s):
  # robot_file_path                 The file path of the robot file (with or
  #                                 without .robot suffix).  This file path is
  #                                 relative to the base git repository.
  # robot_pgm_parms                 A space-separated list of parms which are
  #                                 to be passed to the robot program via the
  #                                 -v robot parameter.  These parms will be
  #                                 processed in addition to the
  #                                 stock_robot_program_parms listed above.
  # robot_gen_parms                 A space-separated list of general robot
  #                                 parameters understood by the robot program
  #                                 (e.g. consolecolors, etc).

  # Strip, then re-append ".robot" so that the user can pass with or without
  # the .robot suffix.
  robot_file_path="${robot_file_path%.robot}.robot"

  # Determine the robot_file_name form the robot_file_path.
  local robot_file_name="${robot_file_path%.robot}"
  robot_file_name="${robot_file_name##*/}"
  local robot_short_file_name="${robot_file_name%.robot}"

  # Set default values for robot_gen_parms.
  local dft_console=dotted
  local dft_consolecolors=off
  local dft_outputdir=/status_dir
  local dft_output=${robot_short_file_name}.output.xml
  local dft_log=${robot_short_file_name}.log.html
  local dft_report=${robot_short_file_name}.report.html
  local dft_loglevel='TRACE'
  local dft_include=''

  local cmd_buf
  # Loop through robot general parms setting any that have no value to a
  # default value (defined above).
  for parm_name in ${robot_gen_parms} ; do
    # If the parm already has a value, continue to next loop iteration.
    [ ! -z "${!parm_name-}" ] && continue || :
    cmd_buf="${parm_name}=\"\${dft_${parm_name}}\""
    eval ${cmd_buf}
  done

  local robot_cmd_buf='robot'
  # Process our stock robot program parms along with the caller's
  # robot_pgm_parms to add to the robot_cmd_buf.
  local parm_name
  local escape_quote_char="'\''"
  for parm_name in ${stock_robot_program_parms} ${robot_pgm_parms} ; do
    [ -z "${parm_name-}" ] && continue
    robot_cmd_buf="${robot_cmd_buf} -v ${parm_name}:${!parm_name-}"
  done

  # Process the robot general parms to add to the robot_cmd_buf.
  for parm_name in ${robot_gen_parms} ; do
    robot_cmd_buf="${robot_cmd_buf} --${parm_name}=${!parm_name-}"
  done

  # Finally append the robot file path to the robot_cmd_buf.
  additional_parms=" ${additional_parms-}"
  robot_cmd_buf="${robot_cmd_buf}${additional_parms} ${HOME}/openbmc-test"
  robot_cmd_buf="${robot_cmd_buf}-automation/${robot_file_path}"

  # Run the docker container to execute the code update.
  # The test results will be put in ${WORKSPACE}.

  cmd_buf="docker run --user=root --env=HOME=${HOME} --env=PYTHONPATH=${HOME}"
  cmd_buf="${cmd_buf}/openbmc-test-automation/lib --workdir=${HOME} --volume"
  cmd_buf="${cmd_buf}=${git_dir_path}:${HOME} --volume=${WORKSPACE}:/status_"
  cmd_buf="${cmd_buf}dir --tty ${DOCKER_IMG_NAME} python -m ${robot_cmd_buf}"
  # Echo all subsequent commands to terminal.
  set -x
  eval "${cmd_buf}"

}
