### YAML Configuration

YAML is a human friendly data serialization standard for all programming languages.

Refer: https://yaml.org/

YAML is the main orchestrator in terms of how the user arranges the data to be
collected in this log collection tool. The better context and syntax usage would
improve the execution, parsing and data collection feeds to the collector engine.


### YAML Rules

The collector parser and engine needs a very minimal set of rules user need to
follow while writing a YAML block. The YAML standards applies as usual.

```
<Block identifier>
    <Sub block for a given protocol group>:
        COMMANDS:
            - <command>
        FILES:
            - <file name to save log>
        PROTOCOL:
            - <supported currently SSH, TELNET, SCP, SHELL>
```

This block statement in YAML one must follow for the collector to do operation
successfully.

COMMANDS, FILES, PROTOCOL is mandatory for all YAML block.

Note: The FILES directive is not needed for protocol using SCP (Refer YAML Block Example)


### YAML Block Examples

Generic syntax usage:

```
OPENBMC:
    OPENBMC_LOGS:
        COMMANDS:
            - 'peltool -l >/tmp/PEL_logs_list.json'
        FILES:
            - '/tmp/PEL_logs_list.json'
        PROTOCOL:
            - 'SSH'

    # DUMP_LOGS: This section provides option to 'SCP if file exist'.
    DUMP_LOGS:
        COMMANDS:
            - 'ls -AX /var/lib/systemd/coredump/core.*'
        PROTOCOL:
            - 'SCP'

    # File contains the data returned from 'redfishtool GET URL'
    REDFISH_LOGS:
        COMMANDS:
            - redfishtool -u ${username} -p ${password} -r ${hostname} -S Always raw GET /redfish/v1/AccountService/Accounts
        FILES:
            - 'REDFISH_bmc_user_accounts.json'
        PROTOCOL:
            - 'REDFISH'

    # Commands and Files to collect for via out of band IPMI.
    IPMI_LOGS:
        COMMANDS:
            - ipmitool -I lanplus -C 17 -U ${username} -P ${password} -H ${hostname} lan print
        FILES:
            - 'IPMI_LAN_print.txt'
        PROTOCOL:
            - 'IPMI'

```

Example of using plugin in YAML (Refer plugin documentation)

```
OPENBMC:
    REDFISH_LOGS:
        COMMANDS
            - plugin:
              - plugin_name: plugin.redfish.enumerate_request
              - plugin_args:
                - ${hostname}
                - ${username}
                - ${password}
                - /redfish/v1/
                - json
        FILES:
            - 'REDFISH_enumerate_v1.json'
        PROTOCOL:
            - 'REDFISH'
```
