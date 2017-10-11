*** Settings ***

Documentation    Module to test REST upload stability.
...              Upload a test file to the BMC.  The
...              test file is approximately the size of
...              a BMC flash image file.

# Test Parameters:
# OPENBMC_HOST        The BMC host name or IP address.
# LOOPS               The number of times to loop the test.
#                     Defaule value for LOOPS is 1.


Library            OperatingSystem
Resource           ../lib/utils.robot


Test Teardown   FFDC On Test Case Fail

*** Variables ****

${LOOPS}         ${1}
${iteration}     ${0}


*** Test Cases ***


REST Upload Stability Test
    [Documentation]  Execute upload stress testing.
    [Tags]  REST_Upload_Stability_Test
    Repeat Keyword  ${LOOPS} times  Upload Test Image File To BMC


*** Keywords ***


Upload Test Image File To BMC
    [Documentation]  Upload a file to BMC via REST.  The uploaded file
    ...              is 32MB, approximately the same size as a downloadable
    ...              BMC image.
    [Timeout]  2m

    # Iteration counter for the Log.
    Set Test Variable  ${iteration}  ${iteration + 1}
    Log To Console  Starting iteration: ${iteration}

    # Generate data file.
    Run  dd if=/dev/zero of=dummyfile bs=1 count=0 seek=32MB
    OperatingSystem.File Should Exist  dummyfile

    ${image_data}=  OperatingSystem.Get Binary File  dummyfile

    # Get REST session to BMC.
    Initialize OpenBMC

    # Create the REST payload headers and data.
    ${data}=  Create Dictionary  data=${image_data}

    ${dict_keys}=  Get Dictionary Keys  ${data}
    ${dict_vals}=  Get Dictionary Values  ${data}

    ${headers}=  Create Dictionary  Content-Type=application/octet-stream
    ...  Accept=application/octet-stream

    Set To Dictionary  ${data}  headers  ${headers}

    # Upload to BMC and check for HTTP_OK.
    ${resp}=  Post Request  openbmc  /upload/image  &{data}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}

    # Delete the image file on the BMC.
    &{bmc_connection_args}=  Create Dictionary  alias=bmc_connection
    Open Connection And Log In  &{bmc_connection_args}
    Execute Command On BMC  rm -f /tmp/images/*

    Log To Console  Finished iteration: ${iteration}
