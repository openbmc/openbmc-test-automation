#!/usr/bin/python


'''
Exports issues from a list of repositories to individual CSV files.
Uses basic authentication (GitHub username + password) to retrieve issues
from a repository that username has access to. Supports GitHub API v3.
'''

class OBMC_Commands_Constants(object):

    # Open BMC commands
    OBMC_CMD = {'CURR_BUILD' : 'cat '}

    # Command Options
    OBMC_CMD_OPTION = {'CURR_BUILD' :
                                        {'OS' : '/etc/os-release',
                                         'VERSION' : '/tmp/out.txt'},
                      }
    # Open BMC CLI Commands
    OBMC_CURRENT_BUILD_IMAGE = OBMC_CMD['CURR_BUILD'] + OBMC_CMD_OPTION['CURR_BUILD']['OS']
    OBMC_CURRENT_BUILD_DETAILS = OBMC_CMD['CURR_BUILD'] + OBMC_CMD_OPTION['CURR_BUILD']['VERSION']


if __name__ == "__main__":
    t = OBMC_Commands_Constants()
    CMD = t.OBMC_CMD
    OPT = t.OBMC_CMD_OPTION



