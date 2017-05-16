***Settings***
Documentation      This module is for generating an inventory file using
...                lshw commands. It will create a JSON file and a YAML
...                file. It will get the processor, memory and specified
...                I/O devices.
            
Library  String
Library  Collections
Library  OperatingSystem

***Variables***
# List of I/O Devices to Collect
@{I/O}  communication  disk  display  generic  input  multimedia  network  printer  tape

# Name of the JSON and YAML files
${jsonfile}  inventory.json
${yamlfile}  inventory.yaml

***Test Case***

Create Intermediate File
  Compile Inventory JSON

Convert Intermediate File to YAMl
  Convert JSON to YAML

***Keywords***

Compile Inventory JSON
  Create File  ${jsonfile}
  Write New JSON List  ${jsonfile}  Inventory
  Retrieve HW Info and Write  processor  ${jsonfile}
  Retrieve HW Info and Write  memory  ${jsonfile}
  Retrieve HW Info and Write List  ${I/O}  ${jsonfile}  I/O  last
  Close New JSON List  ${jsonfile}

Convert JSON to YAML
  RUN  pip install json2yaml
  RUN  json2yaml ${jsonfile} ${yamlfile}

Write New JSON List
  [Arguments]  ${file}  ${name}
  Append to File  ${file}  { "${name}" : [
  
Close New JSON List
  [Arguments]  ${file}
  Append to File  ${file}  ]}

Write Comma
  [Arguments]  ${file}
  Append to File  ${file}  ,

Retrieve HW Info and Write
  [Documentation]  Retrieve and Write info, add a comma if not last item.                                     
  [Arguments]  ${class}  ${file}  ${last}=false
  Write New JSON List  ${file}  ${class}
  ${output} =  Retrieve Hardware Info  ${class}
  ${output} =  Clean Up String  ${output}
  Run Keyword if  ${output.__class__ is not type(None)}
  ...  Append To File  ${file}  ${output}
  Close New JSON List  ${file}
  Run Keyword if  '${last}' == 'false'
  ...  Write Comma  ${file}

Retrieve HW Info and Write List
  [Arguments]  ${list}  ${file}  ${parent}  ${last}=false
  Write New JSON List  ${file}  ${parent}
  : FOR  ${class}  IN  @{list}
  \  ${tail}  Get From List  ${list}  -1
  \  Run Keyword if  '${tail}' == '${class}'  
  \  ...  Retrieve HW Info and Write  ${class}  ${file}  true  
  \  ...  ELSE  Retrieve HW Info and Write  ${class}  ${file}
  Close New JSON List  ${file}
  Run Keyword if  '${last}' == 'false'
  ...  Write Comma  ${file}

Retrieve Hardware Info
  [Arguments]  ${class}
  ${output} =  Run  lshw -c ${class} -json
  ${output} =  Verify JSON string  ${output}
  [Return]  ${output}

Verify JSON String
  [Documentation]  Ensure the JSON string content is seperated by commas.
  [Arguments]  ${unverified}
  ${unverified} =  Convert to String  ${unverified}
  ${verified} =  Replace String Using Regexp  ${unverified}  }\\s*{  },{
  [Return]  ${verified}
 
Clean Up String
  [Documentation]  Remove extra whitespace and trailing commas.
  [Arguments]  ${dirty}
  ${clean} =  Strip String  ${dirty}
  ${lastchar} =  Get Substring  ${clean}  -1
  ${temp} =  Get Substring  ${clean}  0  -1
  ${clean} =  Set Variable If  '${lastchar}' == ','  ${temp}  ${clean}
  [Return]  ${clean}
