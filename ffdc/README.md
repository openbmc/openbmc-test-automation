# CLI options for log collector

```
$ python3 collect_ffdc.py -h
Usage: collect_ffdc.py [OPTIONS]

  Stand alone CLI to generate and collect FFDC from the selected target.

Options:
  -r, --remote TEXT     Hostname/IP of the remote host
  -u, --username TEXT   Username of the remote host.
  -p, --password TEXT   Password of the remote host.
  -c, --config TEXT     YAML Configuration file for log collection.  [default:
                        <local path>/openbmc-test-automation/ffdc/ffdc_config.yaml]
  -l, --location TEXT   Location to save logs  [default: /tmp]
  -t, --type TEXT       OS type of the remote (targeting) host. OPENBMC, RHEL,
                        UBUNTU, SLES, AIX
  -rp, --protocol TEXT  Select protocol to communicate with remote host.
                        [default: ALL]
  -e, --env_vars TEXT   Environment variables e.g: {'var':value}
  -ec, --econfig TEXT   Predefine environment variables, refer
                        en_vars_template.yaml
  --log_level TEXT      Log level (CRITICAL, ERROR, WARNING, INFO, DEBUG)
                        [default: INFO]
  -h, --help            Show this message and exit.
```

# Tools and packages dependencies

```
   Python          3.6.12 or latter
   PyYAML           5.4.1
   click            8.0.1
   paramiko         2.7.2
   redfishtool      1.1.1
   ipmitool         1.8.18
```
