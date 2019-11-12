## Code Update ##

Currently supported BMC and PNOR update formats are UBI and non-UBI.
For code update information, please refer to [code-update.md](https://github.com/openbmc/docs/blob/master/code-update/code-update.md)


* UBI Format *

    For BMC code update, download the system type *.ubi.mdt.tar image from
    https://openpower.xyz/job/openbmc-build/ and run as follows:

    For Witherspoon system:
    ```
    $ cd extended/code_update/
    $ robot -v OPENBMC_HOST:x.x.x.x -v IMAGE_FILE_PATH:<image path>/obmc-phosphor-image-witherspoon.ubi.mtd.tar --include REST_BMC_Code_Update  bmc_code_update.robot
    ```

    For host code update, download the system type *.pnor.squashfs.tar image
    from https://openpower.xyz/job/openpower-op-build/ and run as follows:

    For Witherspoon system:
    ```
    $ cd extended/code_update/
    $ robot -v OPENBMC_HOST:x.x.x.x -v IMAGE_FILE_PATH:<image path>/witherspoon.pnor.squashfs.tar --include REST_Host_Code_Update  host_code_update.robot
    ```

* Non-UBI Format *

    For BMC code update, download the system type *all.tar image from
    https://openpower.xyz/job/openbmc-build/ and run as follows:

    For a Zaius system:
    ```
    $ cd extended/code_update/
    $ robot -v OPENBMC_HOST:x.x.x.x -v FILE_PATH:<image path>/zaius-<date time>.all.tar --include Initiate_Code_Update_BMC update_bmc.robot
    ```

    For host code update, download the system type *.pnor from
    https://openpower.xyz/job/openpower-op-build/ and run as follows:

    For a Zaius system:
    ```
    $ cd extended/
    $ robot -v OPENBMC_HOST:x.x.x.x -v PNOR_IMAGE_PATH:<image path>/zaius.pnor test_bios_update.robot
    ```
