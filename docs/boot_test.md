Boot test is one of the cornerstone of OpenBMC test infrastructure.

The boot plugins are used in the test and as well can be use a stand-alone mechanism to test your system to run variety of supported boot sequences.

**Boot test sequence example:**

```
robot -v OPENBMC_HOST:xx.xx.xx.xx  -v 'boot_stack:<boot1>:<boot2>:<bootn>:' extended/obmc_boot_test.robot
```
Where <bootx> is the supported boot type listed in the [data/boot_lists/All](https://github.com/openbmc/openbmc-test-automation/blob/master/data/boot_lists/All)

**Example:**
```
robot -v OPENBMC_HOST:xx.xx.xx.xx  -v 'boot_stack:Redfish Power On:Redfish Power Off' extended/obmc_boot_test.robot
```

and it will give the following on the console the boot test report:

```
Boot Type                                Total Pass Fail
---------------------------------------- ----- ---- ----
Redfish Power On                             1    1    0
Redfish Power On (mfg)                       0    0    0
IPMI Power On                                0    0    0
IPMI Power On (mfg)                          0    0    0
Redfish Power Off                            1    1    0
Redfish Power Off (mfg)                      0    0    0
Redfish Hard Power Off                       0    0    0
Redfish Hard Power Off (mfg)                 0    0    0
IPMI Power Off                               0    0    0
IPMI Power Off (mfg)                         0    0    0
IPMI Power Soft                              0    0    0
IPMI Power Soft (mfg)                        0    0    0
Host Power Off                               0    0    0
Host Power Off (mfg)                         0    0    0
APOR                                         0    0    0
APOR (mfg)                                   0    0    0
OBMC Reboot (run)                            0    0    0
OBMC Reboot (run) (mfg)                      0    0    0
Redfish OBMC Reboot (run)                    0    0    0
Redfish OBMC Reboot (run) (mfg)              0    0    0
OBMC Reboot (off)                            0    0    0
OBMC Reboot (off) (mfg)                      0    0    0
Redfish OBMC Reboot (off)                    0    0    0
Redfish OBMC Reboot (off) (mfg)              0    0    0
PDU AC Cycle (run)                           0    0    0
PDU AC Cycle (run) (mfg)                     0    0    0
PDU AC Cycle (off)                           0    0    0
PDU AC Cycle (off) (mfg)                     0    0    0
IPMI MC Reset Warm (run)                     0    0    0
IPMI MC Reset Warm (run) (mfg)               0    0    0
IPMI MC Reset Warm (off)                     0    0    0
IPMI MC Reset Warm (off) (mfg)               0    0    0
IPMI MC Reset Cold (run)                     0    0    0
IPMI MC Reset Cold (run) (mfg)               0    0    0
IPMI MC Reset Cold (off)                     0    0    0
IPMI MC Reset Cold (off) (mfg)               0    0    0
IPMI Std MC Reset Warm (run)                 0    0    0
IPMI Std MC Reset Warm (run) (mfg)           0    0    0
IPMI Std MC Reset Warm (off)                 0    0    0
IPMI Std MC Reset Warm (off) (mfg)           0    0    0
IPMI Std MC Reset Cold (run)                 0    0    0
IPMI Std MC Reset Cold (run) (mfg)           0    0    0
IPMI Std MC Reset Cold (off)                 0    0    0
IPMI Std MC Reset Cold (off) (mfg)           0    0    0
IPMI Power Cycle                             0    0    0
IPMI Power Cycle (mfg)                       0    0    0
IPMI Power Reset                             0    0    0
IPMI Power Reset (mfg)                       0    0    0
Auto Reboot                                  0    0    0
Auto Reboot (mfg)                            0    0    0
Host Reboot                                  0    0    0
Host Reboot (mfg)                            0    0    0
RF SYS GracefulRestart                       0    0    0
RF SYS GracefulRestart (mfg)                 0    0    0
RF SYS ForceRestart                          0    0    0
RF SYS ForceRestart (mfg)                    0    0    0
OPAL TI                                      0    0    0
OPAL TI (mfg)                                0    0    0
========================================================
Totals                                       2    2    0
```
