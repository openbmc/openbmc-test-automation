## Code Update ##

#### Redfish Code Update ####

Currently supported BMC and PNOR update formats are UBI.
For code update information, please refer to [code-update.md](https://github.com/openbmc/docs/blob/master/code-update/code-update.md)

* UBI Format

    For BMC code update, download the system type *.ubi.mdt.tar image from
    https://jenkins.openbmc.org/job/latest-master/ and run as follows:

    For Witherspoon system:
    ```
    * Code Update with OnReset Policy

        $ cd redfish/update_service/test_redfish_bmc_code_update.robot
        $ robot -v OPENBMC_HOST:x.x.x.x -v IMAGE_FILE_PATH:<image path>/obmc-phosphor-image-witherspoon.ubi.mtd.tar --include Redfish_Code_Update_With_ApplyTime_OnReset redfish/update_service/test_redfish_bmc_code_update.robot

    * Code Update with Immediate Policy

        $ cd redfish/update_service/test_redfish_bmc_code_update.robot
        $ robot -v OPENBMC_HOST:x.x.x.x -v IMAGE_FILE_PATH:<image path>/obmc-phosphor-image-witherspoon.ubi.mtd.tar --include Redfish_Code_Update_With_ApplyTime_Immediate redfish/update_service/test_redfish_bmc_code_update.robot
    ```

    For host code update, download the system type *.pnor.squashfs.tar image
    from https://openpower.xyz/job/openpower-op-build/ and run as follows:

    For Witherspoon system:
    ```
    * Code Update with OnReset Policy

        $ cd redfish/update_service/test_redfish_host_code_update.robot
        $ robot -v OPENBMC_HOST:x.x.x.x -v IMAGE_FILE_PATH:<image path>/witherspoon.pnor.squashfs.tar --include Redfish_Code_Update_With_ApplyTime_OnReset redfish/update_service/test_redfish_host_code_update.robot

    * Code Update with Immediate Policy

        $ cd redfish/update_service/test_redfish_host_code_update.robot
        $ robot -v OPENBMC_HOST:x.x.x.x -v IMAGE_FILE_PATH:<image path>/witherspoon.pnor.squashfs.tar --include Redfish_Code_Update_With_ApplyTime_Immediate redfish/update_service/test_redfish_host_code_update.robot
    ```

#### REST Code Update ####

Currently supported BMC and PNOR update formats are UBI and non-UBI.
For code update information, please refer to [code-update.md](https://github.com/openbmc/docs/blob/master/code-update/code-update.md)


* UBI Format

    For BMC code update, download the system type *.ubi.mdt.tar image from
    https://jenkins.openbmc.org/job/latest-master/ and run as follows:

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

* Non-UBI Format

    For BMC code update, download the system type *all.tar image from
    https://jenkins.openbmc.org/job/latest-master/ and run as follows:

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
