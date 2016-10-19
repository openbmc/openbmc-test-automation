*** Settings ***
Documentation          This example demonstrates executing commands on a remote machine
...                    and getting their output and the return code.
...
...                    Notice how connections are handled as part of the suite setup and
...                    teardown. This saves some time when executing several test cases.

Resource        ../lib/rest_client.robot
Resource        ../lib/ipmi_client.robot
Resource        ../lib/openbmc_ffdc.robot
Resource        ../lib/utils.robot
Library         ../data/model.py

Suite setup            Setup The Suite
Suite Teardown         Close All Connections
Test Teardown          FFDC On Test Case Fail
[return]     ${x}


