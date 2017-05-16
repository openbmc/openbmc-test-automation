***Settings***
Documentation       This module is for generating an inventory file using lshw
...                 commands. It will create a JSON file and a YAML file. it
...                 will get the processor, memory and specified I/O devices.
...                 Requires access to lshw, and json2yaml OS commands. This
...                 robot file should be run as root or sudo for lshw.

Library             String
Library             Collections
Library             OperatingSystem

***Variables***
# List of I/O Devices to Collect
@{I/O}              communication  disk  display  generic  input  multimedia
...                 network  printer  tape

# Paths of the JSON and YAML files
${json_file_path}   inventory.json
${yaml_file_path}   inventory.yaml

***Test Case***

Create YAML Inventory File
  [Tags]            Create_YAML_Inventory_File
  [Documentation]   Create a JSON inventory file, and make a YAML copy.
  Compile Inventory JSON
  Convert JSON To YAML

***Keywords***

Compile Inventory JSON
  [Documentation]   Compile the Inventory into a JSON file.
  Create File  ${json_file_path}
  Write New JSON List  ${json_file_path}  Inventory
  Retrieve HW Info And Write  processor  ${json_file_path}
  Retrieve HW Info And Write  memory  ${json_file_path}
  Retrieve HW Info And Write List  ${I/O}  ${json_file_path}  I/O  last
  Close New JSON List  ${json_file_path}

Convert JSON To YAML
  [Documentation]   Use the CLI tool json2yaml to create YAML file from JSON.
  RUN  json2yaml ${json_file_path} ${yaml_file_path}

Write New JSON List
  [Documentation]   Start a new JSON list element in file.
  [Arguments]       ${json_file_path}  ${json_field_name}
  # Description of argument(s):
  # json_file_path  Name of file to write to.
  # json_field_name Name to give json list element.
  Append to File  ${json_file_path}  { "${json_field_name}" : [

Close New JSON List
  [Documentation]   Close JSON list element in file.
  [Arguments]  ${json_file_path}
  # Description of argument(s):
  # json_file_path  Path of file to write to.
  Append to File  ${json_file_path}  ]}

Retrieve HW Info And Write
  [Documentation]   Retrieve and write info, add a comma if not last item.
  [Arguments]       ${class}  ${json_file_path}  ${last}=false
  # Description of argument(s):
  # class           Device class to retrieve with lshw.
  # json_file_path  Path of file to write to.
  # last            Is this the last element in the parent JSON?
  Write New JSON List  ${json_file_path}  ${class}
  ${output} =  Retrieve Hardware Info  ${class}
  ${output} =  Clean Up String  ${output}
  Run Keyword if  ${output.__class__ is not type(None)}
  ...  Append To File  ${json_file_path}  ${output}
  Close New JSON List  ${json_file_path}
  Run Keyword if  '${last}' == 'false'
  ...  Append to File  ${json_file_path}  ,

Retrieve HW Info And Write List
  [Documentation]   Does a Retrieve/Write with a list of classes and
  ...               encapsulates them into one large JSON element.
  [Arguments]       ${list}  ${json_file_path}  ${json_field_name}
  ...               ${last}=false
  # Description of argument(s):
  # list            The list of devices classes to retrieve with lshw.
  # json_file_path  Path of file to write to.
  # json_field_name Name of the JSON element to encapsulate this list.
  # last            Is this the last element in the parent JSON?
  Write New JSON List  ${json_file_path}  ${json_field_name}
  : FOR  ${class}  IN  @{list}
  \  ${tail}  Get From List  ${list}  -1
  \  Run Keyword if  '${tail}' == '${class}'
  \  ...  Retrieve HW Info And Write  ${class}  ${json_file_path}  true
  \  ...  ELSE  Retrieve HW Info And Write  ${class}  ${json_file_path}
  Close New JSON List  ${json_file_path}
  Run Keyword if  '${last}' == 'false'
  ...  Append to File  ${json_file_path}  ,

Retrieve Hardware Info
  [Documentation]   Retrieves the lshw output of the device class as JSON.
  [Arguments]       ${class}
  # Description of argument(s):
  # class           device class to retrieve with lshw.
  ${output} =  Run  lshw -c ${class} -json
  ${output} =  Verify JSON string  ${output}
  [Return]  ${output}

Verify JSON String
  [Documentation]   Ensure the JSON string content is seperated by commas.
  [Arguments]       ${unver_string}
  # Description of argument(s):
  # unver_string    JSON String we will be checking for lshw comma errors.
  ${unver_string} =  Convert to String  ${unver_string}
  ${ver_string} =  Replace String Using Regexp  ${unver_string}  }\\s*{  },{
  [Return]  ${ver_string}

Clean Up String
  [Documentation]   Remove extra whitespace and trailing commas.
  [Arguments]       ${dirty_string}
  # Description of argument(s):
  # dirty_string    String that will be space stripped and have comma removed.
  ${clean_string} =  Strip String  ${dirty_string}
  ${last_char} =  Get Substring  ${clean_string}  -1
  ${trimmed_string} =  Get Substring  ${clean_string}  0  -1
  ${clean_string} =  Set Variable If  '${last_char}' == ','
  ...  ${trimmed_string}  ${clean_string}
  [Return]  ${clean_string}