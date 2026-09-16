*** Settings ***
Documentation    BIOS Attribute Registry provisioning for Qualcomm EVB
...              bring-up boards: PUT a test AttributeRegistry payload and
...              verify it round-trips. Assumes a bootstrap-credentialed
...              Redfish session is already active (see Setup Bios
...              Resource Test Suite in
...              redfish/systems/test_bios_resource.robot).
...              Test Environment:
...              - BMC: AST2600 at ${OPENBMC_HOST}  (pass --variable OPENBMC_HOST:<ip> at runtime)
...              - Host: Raspberry Pi (RPI) at ${HOST_IP}
...              - USB Ethernet: BMC at ${BMC_USB_ETH_IP}, Host at ${HOST_USB_ETH_IP}

Resource         ../../resource.resource
Library          ../../../../lib/bios_attribute_registry.py


*** Keywords ***

Create BIOS Attribute Registry Table On EVB
    [Documentation]  On EVB, PUT a 5-attribute test registry to
    ...  BiosAttributeRegistry using the active bootstrap-credentialed
    ...  session, then read it back and verify it round-trips.
    ...
    ...  Retries the PUT: observed returning 405 shortly after a BMC
    ...  boot/reboot, presumably while the backend service that registers
    ...  this route is still coming up.

    IF  not ${PLATFORM_IS_EVB}
        Log  Skipping BIOS Attribute Registry creation; not an EVB platform.
        RETURN
    END

    ${registry}=  Build Test Attribute Registry

    Wait Until Keyword Succeeds  1 min  10 sec  Redfish.Put  ${BIOS_ATTR_REGISTRY_URI}
    ...  body=${registry}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_CREATED}, ${HTTP_NO_CONTENT}]

    ${actual_registry}=  Redfish.Get Properties  ${BIOS_ATTR_REGISTRY_URI}
    ...  valid_status_codes=[${HTTP_OK}]

    ${mismatches}=  Compare Attribute Registries  ${registry}  ${actual_registry}
    Should Be Empty  ${mismatches}
    ...  msg=BIOS Attribute Registry did not round-trip correctly: ${mismatches}