#!/usr/bin/env python3

r"""
This module builds a sample DMTF Redfish AttributeRegistry payload used to
provision the BiosAttributeRegistry resource on AST2600 EVB platforms (the
"edk2 simplified" model: PUT the whole registry directly to
<Bios Resource URI>/<AttributeRegistry value>, rather than traversing
/redfish/v1/Registries).
"""

REGISTRY_ODATA_TYPE = "#AttributeRegistry.v1_5_0.AttributeRegistry"


def build_test_attribute_registry(registry_id: str = "BiosAttributeRegistry") -> dict:
    """Build a DMTF AttributeRegistry payload with 5 test BIOS attributes
    (String, Integer, Boolean, Enumeration, String), suitable for PUTing
    to a Bios/<AttributeRegistry> resource.

    Example call from Robot Framework:
    ${registry}=  Build Test Attribute Registry

    Description of argument(s):
    registry_id  The registry "Id" to use; must match the Bios resource's
                 own "AttributeRegistry" field (e.g. "BiosAttributeRegistry").
    """


    attributes = [
        {
            "AttributeName": "TestAttrString",
            "Type": "String",
            "DisplayName": "Test String Attribute",
            "HelpText": "A test BIOS attribute of type String.",
            "MenuPath": "./Advanced/Test",
            "CurrentValue": "current_val",
            "DefaultValue": "default_val",
            "MinLength": 0,
            "MaxLength": 64,
            "ReadOnly": False,
        },
        {
            "AttributeName": "TestAttrInteger",
            "Type": "Integer",
            "DisplayName": "Test Integer Attribute",
            "HelpText": "A test BIOS attribute of type Integer.",
            "MenuPath": "./Advanced/Test",
            "CurrentValue": 5,
            "DefaultValue": 10,
            "LowerBound": 0,
            "UpperBound": 100,
            "ScalarIncrement": 1,
            "ReadOnly": False,
        },
        {
            "AttributeName": "TestAttrBoolean",
            "Type": "Boolean",
            "DisplayName": "Test Boolean Attribute",
            "HelpText": "A test BIOS attribute of type Boolean.",
            "MenuPath": "./Advanced/Test",
            "CurrentValue": True,
            "DefaultValue": False,
            "ReadOnly": False,
        },
        {
            "AttributeName": "TestAttrEnumeration",
            "Type": "Enumeration",
            "DisplayName": "Test Enumeration Attribute",
            "HelpText": "A test BIOS attribute of type Enumeration.",
            "MenuPath": "./Advanced/Test",
            "CurrentValue": "OptionA",
            "DefaultValue": "OptionA",
            "Value": [
                {"ValueName": "OptionA", "ValueDisplayName": "Option A"},
                {"ValueName": "OptionB", "ValueDisplayName": "Option B"},
                {"ValueName": "OptionC", "ValueDisplayName": "Option C"},
            ],
            "ReadOnly": False,
        },
        {
            "AttributeName": "TestAttrStringTwo",
            "Type": "String",
            "DisplayName": "Test String Attribute Two",
            "HelpText": "A second test BIOS attribute of type String.",
            "MenuPath": "./Advanced/Test",
            "CurrentValue": "second_val",
            "DefaultValue": "second_default",
            "MinLength": 0,
            "MaxLength": 32,
            "ReadOnly": False,
        },
    ]

    return {
        "Id": registry_id,
        "Name": "BIOS Attribute Registry",
        "Language": "en",
        "OwningEntity": "BIOS",
        "RegistryVersion": "1.0.0",
        "@odata.type": REGISTRY_ODATA_TYPE,
        "RegistryEntries": {"Attributes": attributes},
    }


def expected_pending_defaults_after_reset(
    registry: dict, exclude_types: frozenset = frozenset()
) -> dict:
    """Build the {AttributeName: DefaultValue} mapping ResetBios is
    expected to stage into pending Settings, given an AttributeRegistry
    payload.

    Example call from Robot Framework:
    ${registry}=  Build Test Attribute Registry
    ${expected}=  Expected Pending Defaults After Reset  ${registry}

    Description of argument(s):
    registry       An AttributeRegistry payload (e.g. from
                    build_test_attribute_registry).
    exclude_types   Attribute "Type" values to leave out of the expected
                    mapping (e.g. because the firmware is known not to
                    stage them).
    """

    return {
        attribute["AttributeName"]: attribute["DefaultValue"]
        for attribute in registry["RegistryEntries"]["Attributes"]
        if attribute["Type"] not in exclude_types
    }


def compare_attribute_registries(expected: dict, actual: dict) -> list[str]:
    """Compare two AttributeRegistry payloads' RegistryEntries.Attributes
    lists for full equality (order-independent, keyed by AttributeName).

    Example call from Robot Framework:
    ${mismatches}=  Compare Attribute Registries  ${sent}  ${read_back}

    Description of argument(s):
    expected  The AttributeRegistry payload that was sent (e.g. via PUT).
    actual    The AttributeRegistry payload read back (e.g. via GET).

    Returns a list of mismatch descriptions; empty means the payloads
    match exactly.
    """

    expected_by_name = {
        attribute["AttributeName"]: attribute
        for attribute in expected["RegistryEntries"]["Attributes"]
    }
    actual_by_name = {
        attribute["AttributeName"]: attribute
        for attribute in actual.get("RegistryEntries", {}).get("Attributes", [])
    }

    mismatches = []
    for name, expected_attribute in expected_by_name.items():
        actual_attribute = actual_by_name.get(name)
        if actual_attribute is None:
            mismatches.append(f"Attribute '{name}' missing from read-back registry.")
            continue
        for key, expected_value in expected_attribute.items():
            actual_value = actual_attribute.get(key)
            if actual_value != expected_value:
                mismatches.append(
                    f"Attribute '{name}' field '{key}': expected {expected_value!r}, got {actual_value!r}."
                )
        for key in actual_attribute.keys() - expected_attribute.keys():
            mismatches.append(
                f"Attribute '{name}' field '{key}': unexpected in read-back registry "
                f"(value {actual_attribute[key]!r})."
            )

    for name in actual_by_name.keys() - expected_by_name.keys():
        mismatches.append(f"Attribute '{name}' unexpectedly present in read-back registry.")

    return mismatches