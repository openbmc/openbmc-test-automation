### OpenBMC Test Architecture Model

### OpenBMC Supported Interfaces

```

                                 ---------
                                | OpenBMC |
                                 ---------
                                   |
      -----------------------------------------------------------------
      |                   |                 |                         |
   ---------            ------            ---------               --------------
  | Redfish |          | IPMI |          | Web GUI |             | Legacy REST  |
   ---------            ------            ---------               --------------
```

NOTE: Legacy REST will be deprecated at some point and therefore no longer supported.


### OpenBMC Test Method Supports

```
                                 ----------
                                | Test BMC |
                                 ----------
                                     |
         -----------------------------------------------------------
         |                           |                             |
     -----------               -----------------              -----------
    | Boot Test |             | Functional Test |            | Host Test |
     -----------               -----------------              ------------
         |                           |                             |
    ******************   *****************************    ********************
    | Interfaces:    |   | Interfaces:               |    | Interfaces:      |
    |   - REST/IPMI  |   |   - REST/IPMI/GUI         |    |   - REST/Tools   |
    | Power on       |   | Minimal Boot Test         |    | HTX boot runs    |
    | Power off      |   | Interfaces Functions      |    | Host IO/OS test  |
    | BMC/Host reset |   | System Functionality      |    | System RAS       |
    ******************   *****************************    ********************

```
