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

#### Bad Firmware File ####

Below procedure is to create bad firmware file for bmc and similar steps applicable for pnor.

*   Bad manifest file

    ```
    Below command to list the tart files.

    tar -tvf obmc-phosphor-image-witherspoon-20210516025203.ubi.mtd.tar
    -rw-r--r-- jenkins-op/jenkins-op 306804 2021-05-15 22:00 image-u-boot
    -rw-r--r-- jenkins-op/jenkins-op 3039300 2021-05-12 03:32 image-kernel
    -rw-r--r-- jenkins-op/jenkins-op 19861504 2021-05-15 22:00 image-rofs
    -rw-r--r-- jenkins-op/jenkins-op   850304 2021-05-15 22:00 image-rwfs
    -rw-r--r-- jenkins-op/jenkins-op      176 2021-05-15 22:00 MANIFEST
    -rw-r--r-- jenkins-op/jenkins-op      272 2021-05-15 22:00 publickey
    -rw-r--r-- jenkins-op/jenkins-op      128 2021-05-15 22:00 image-u-boot.sig
    -rw-r--r-- jenkins-op/jenkins-op      128 2021-05-15 22:00 image-kernel.sig
    -rw-r--r-- jenkins-op/jenkins-op      128 2021-05-15 22:00 image-rofs.sig
    -rw-r--r-- jenkins-op/jenkins-op      128 2021-05-15 22:00 image-rwfs.sig
    -rw-r--r-- jenkins-op/jenkins-op      128 2021-05-15 22:00 MANIFEST.sig
    -rw-r--r-- jenkins-op/jenkins-op      128 2021-05-15 22:00 publickey.sig
    -rw-r--r-- jenkins-op/jenkins-op      128 2021-05-15 22:00 image-full.sig

    Below command to delete particular file.

    tar --delete -vf obmc-phosphor-image-witherspoon-20210516025203.ubi.mtd.tar MANIFEST

    tar -tvf obmc-phosphor-image-witherspoon-20210516025203.ubi.mtd.tar
    -rw-r--r-- jenkins-op/jenkins-op 306804 2021-05-15 22:00 image-u-boot
    -rw-r--r-- jenkins-op/jenkins-op 3039300 2021-05-12 03:32 image-kernel
    -rw-r--r-- jenkins-op/jenkins-op 19861504 2021-05-15 22:00 image-rofs
    -rw-r--r-- jenkins-op/jenkins-op   850304 2021-05-15 22:00 image-rwfs
    -rw-r--r-- jenkins-op/jenkins-op      272 2021-05-15 22:00 publickey
    -rw-r--r-- jenkins-op/jenkins-op      128 2021-05-15 22:00 image-u-boot.sig
    -rw-r--r-- jenkins-op/jenkins-op      128 2021-05-15 22:00 image-kernel.sig
    -rw-r--r-- jenkins-op/jenkins-op      128 2021-05-15 22:00 image-rofs.sig
    -rw-r--r-- jenkins-op/jenkins-op      128 2021-05-15 22:00 image-rwfs.sig
    -rw-r--r-- jenkins-op/jenkins-op      128 2021-05-15 22:00 MANIFEST.sig
    -rw-r--r-- jenkins-op/jenkins-op      128 2021-05-15 22:00 publickey.sig
    -rw-r--r-- jenkins-op/jenkins-op      128 2021-05-15 22:00 image-full.sig

    Below command to change the file name.

    mv obmc-phosphor-image-witherspoon-20210516025203.ubi.mtd.tar bmc_bad_manifest.ubi.mtd.tar
    ```

*   Nokernel image

    ```
    Below command to list the tart files.

    tar -tvf obmc-phosphor-image-witherspoon-20210516025203.ubi.mtd.tar
    -rw-r--r-- jenkins-op/jenkins-op 306804 2021-05-15 22:00 image-u-boot
    -rw-r--r-- jenkins-op/jenkins-op 3039300 2021-05-12 03:32 image-kernel
    -rw-r--r-- jenkins-op/jenkins-op 19861504 2021-05-15 22:00 image-rofs
    -rw-r--r-- jenkins-op/jenkins-op   850304 2021-05-15 22:00 image-rwfs
    -rw-r--r-- jenkins-op/jenkins-op      176 2021-05-15 22:00 MANIFEST
    -rw-r--r-- jenkins-op/jenkins-op      272 2021-05-15 22:00 publickey
    -rw-r--r-- jenkins-op/jenkins-op      128 2021-05-15 22:00 image-u-boot.sig
    -rw-r--r-- jenkins-op/jenkins-op      128 2021-05-15 22:00 image-kernel.sig
    -rw-r--r-- jenkins-op/jenkins-op      128 2021-05-15 22:00 image-rofs.sig
    -rw-r--r-- jenkins-op/jenkins-op      128 2021-05-15 22:00 image-rwfs.sig
    -rw-r--r-- jenkins-op/jenkins-op      128 2021-05-15 22:00 MANIFEST.sig
    -rw-r--r-- jenkins-op/jenkins-op      128 2021-05-15 22:00 publickey.sig
    -rw-r--r-- jenkins-op/jenkins-op      128 2021-05-15 22:00 image-full.sig

    Below command to delete particular file.

    tar --delete -vf obmc-phosphor-image-witherspoon-20210516025203.ubi.mtd.tar image-kernel

    tar -tvf obmc-phosphor-image-witherspoon-20210516025203.ubi.mtd.tar
    -rw-r--r-- jenkins-op/jenkins-op 306804 2021-05-15 22:00 image-u-boot
    -rw-r--r-- jenkins-op/jenkins-op 19861504 2021-05-15 22:00 image-rofs
    -rw-r--r-- jenkins-op/jenkins-op   850304 2021-05-15 22:00 image-rwfs
    -rw-r--r-- jenkins-op/jenkins-op      176 2021-05-15 22:00 MANIFEST
    -rw-r--r-- jenkins-op/jenkins-op      272 2021-05-15 22:00 publickey
    -rw-r--r-- jenkins-op/jenkins-op      128 2021-05-15 22:00 image-u-boot.sig
    -rw-r--r-- jenkins-op/jenkins-op      128 2021-05-15 22:00 image-kernel.sig
    -rw-r--r-- jenkins-op/jenkins-op      128 2021-05-15 22:00 image-rofs.sig
    -rw-r--r-- jenkins-op/jenkins-op      128 2021-05-15 22:00 image-rwfs.sig
    -rw-r--r-- jenkins-op/jenkins-op      128 2021-05-15 22:00 MANIFEST.sig
    -rw-r--r-- jenkins-op/jenkins-op      128 2021-05-15 22:00 publickey.sig
    -rw-r--r-- jenkins-op/jenkins-op      128 2021-05-15 22:00 image-full.sig

    Below command to change the file name.

    mv obmc-phosphor-image-witherspoon-20210516025203.ubi.mtd.tar bmc_nokernel_image.ubi.mtd.tar
    ```

*   Invalid key image

    ```
    Untar the firmware image.

    tar -xvf obmc-phosphor-image-witherspoon-20210516025203.ubi.mtd.tar -C /directory_path/untar_files/
    image-u-boot
    image-kernel
    image-rofs
    image-rwfs
    MANIFEST
    publickey
    image-u-boot.sig
    image-kernel.sig
    image-rofs.sig
    image-rwfs.sig
    MANIFEST.sig
    publickey.sig
    image-full.sig

    Change few random characters in public key like in below example replace first few characters to openbmc.

    cat publickey
    -----BEGIN PUBLIC KEY-----
    openbmcbmcCSqGSIb3DQEBAQUAA4GNADCBiQKBgQD70gy7urJZD9YK4j2nkFy/crA+
    vSfx42wQiENET33lgW++VEtbUU4zz9FG/ArR/BMVX/IhdbpbGQO/AcyIwWGVafac
    g+i26Wf4Y1e6yB+nUzYaFaXQPhfC85kO3MoRxvJdiTL3bp8Bdrl+ZA+Fg3GbfyEy
    mTUDWrz7ZiMg+R6a3QIDAQCD
    -----END PUBLIC KEY-----

    tar the firmware image files.

    tar -cvf bmc_invalid_key.ubi.mtd.tar *
    ```
