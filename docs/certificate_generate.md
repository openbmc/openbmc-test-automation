## Steps to create and install CA signed certificate

To create and install a CA signed server certificate, follow these steps:

A. Create your own SSL certificate authority
B. Generate CSR for server certificate
C. Create CA signed server certificate using CSR request
D. Install CA signed server certificate

**Create your own SSL certificate authority**

1. Create private key for certificate authority(CA).


```openssl genrsa -des3 -out rootCA.key 2048```

Note: You will be prompted to give a password for private key. This password will be used whenever the private key is used.


2. Create a root CA certificate using the private key created in step 1.

```openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 1024 -out rootCA.pem```

This will start an interactive script to enter information that will be incorporated into your certificate request.

```
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [AU]:US
State or Province Name (full name) [Some-State]:Oregon
Locality Name (eg, city) []:Portland
Organization Name (eg, company) [Internet Widgits Pty Ltd]:Overlords
Organizational Unit Name (eg, section) []:IT
Common Name (eg, YOUR name) []:Data Center Overlords
Email Address []:none@none.com
```

**Generate CSR for server certificate**

1. Create CSR request file (csr_file.json) with all of the following fields.

```
{
    "City": <City Name>,
    "CertificateCollection": {
        "@odata.id": "/redfish/v1/Managers/bmc/NetworkProtocol/HTTPS/Certificates/"
    },
    "CommonName": "<BMC_IP>",
    "Country": <Country Name>,
    "Organization": <Organization Name>,
    "OrganizationalUnit": <Organization Unit Name>,
    "State": <State Name>,
    "KeyPairAlgorithm": <RSA/EC>
}
```

Example:
```
{
    "City": "Austin",
    "CertificateCollection": {
        "@odata.id": "/redfish/v1/Managers/bmc/NetworkProtocol/HTTPS/Certificates/"
    },
    "CommonName": "9.3.111.222",
    "Country": "US",
    "Organization": "IBM",
    "OrganizationalUnit": "ISL",
    "State": "AU",
    "KeyPairAlgorithm": "RSA"
}
```

2. Generate CSR request using the following Redfish command.

```
$ curl -c cjar -b cjar -k -H "X-Auth-Token: $bmc_token" -X POST https://${BMC_IP}/redfish/v1/CertificateService/Actions/CertificateService.GenerateCSR/ -d @csr_file.json
{
  "CSRString": "-----BEGIN CERTIFICATE REQUEST-----\nMIIBZzCCARECAQEwgasxJTAjBgNVHREMHHdzYm1jMDE1LmF1cy5zdGdsYWJzLmli\nbS5jb20xDzANBgNVBAcMBkF1c3RpbjESMBAGA1UEA  wwJOS4zLjIxLjU1MQ8wDQYD\nVQQpDAZteW5hbWUxCzAJBgNVBAYTAlVTMQ0wCwYEKw4DAgwDUlNBMRUwEwYDVR0P\nDAxLZXlBZ3JlZW1lbnQxDDAKBgNVBA  oMA0lCTTELMAkGA1UECAwCQVUwXDANBgkq\nhkiG9w0BAQEFAANLADBIAkEAwY9eVEdOobpT646Ssn7QmcxLeoWnCIulyP3hKR2f\n4E8Cy3FdO/j3HlrlKxJ  ijB8eBDmdB0zR8CnVUipUcknj4QIDAQABoAAwDQYJKoZI\nhvcNAQELBQADQQBcKCRdSZxqKoH7h4uta27Qchna88ljrJwX3PLqNES5nyCUaacx\ne8Xqddi9  iG7FcnULE9VLzhpr86UTZV4393+s\n-----END CERTIFICATE REQUEST-----\n",
  "CertificateCollection": {
    "@odata.id": "/redfish/v1/Managers/bmc/NetworkProtocol/HTTPS/Certificates/"
  }
}
```

3. Convert response into .csr file (device.csr)

```
$ cat device.csr
-----BEGIN CERTIFICATE REQUEST-----
MIIBZzCCARECAQEwgasxJTAjBgNVHREMHHdzYm1jMDE1LmF1cy5zdGdsYWJzLmli
bS5jb20xDzANBgNVBAcMBkF1c3RpbjESMBAGA1UEAwwJOS4zLjIxLjU1MQ8wDQYD
VQQpDAZteW5hbWUxCzAJBgNVBAYTAlVTMQ0wCwYEKw4DAgwDUlNBMRUwEwYDVR0P
DAxLZXlBZ3JlZW1lbnQxDDAKBgNVBAoMA0lCTTELMAkGA1UECAwCQVUwXDANBgkq
hkiG9w0BAQEFAANLADBIAkEAwY9eVEdOobpT646Ssn7QmcxLeoWnCIulyP3hKR2f
4E8Cy3FdO/j3HlrlKxJijB8eBDmdB0zR8CnVUipUcknj4QIDAQABoAAwDQYJKoZI
hvcNAQELBQADQQBcKCRdSZxqKoH7h4uta27Qchna88ljrJwX3PLqNES5nyCUaacx
e8Xqddi9iG7FcnULE9VLzhpr86UTZV4393+s
-----END CERTIFICATE REQUEST-----
```

**Create CA signed server certificate using CSR request**

1. Use BMC generated CSR request (device.csr) to generate CA signed certificate (device.crt).
```
openssl x509 -req -in device.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out device.crt -days 500 -sha256
```


2. Create JSON file (certificate.json) with the device.crt file created in step 1.

```
$ cat certificate.json
{
    "CertificateString": "-----BEGIN CERTIFICATE-----\nMIIC+TCCAeECCQCk+dNJDXfI1jANBgkqhkiG9w0BAQsFADCBmDELMAkGA1UEBhMC\nSU4xDjAMBgNVBAgMBURFTEhJMQ4wDAYDVQQHD  AVERUxISTEeMBwGA1UECgwVQ0VS\nVElGSUNBVEUgQVVUSE9SSVRZMQswCQYDVQQLDAJJVDEeMBwGA1UEAwwVRGF0YSBD\nZW50ZXIgT3ZlcmxvcmRzMRwwGg  YJKoZIhvcNAQkBFg1ub25lQG5vbmUuY29tMB4X\nDTE5MDYyNzExMTczNloXDTIwMTEwODExMTczNlowgasxJTAjBgNVHREMHHdzYm1j\nMDE1LmF1cy5zdGd  sYWJzLmlibS5jb20xDzANBgNVBAcMBkF1c3RpbjESMBAGA1UE\nAwwJOS4zLjIxLjU1MQ8wDQYDVQQpDAZteW5hbWUxCzAJBgNVBAYTAlVTMQ0wCwYE\nKw4D  AgwDUlNBMRUwEwYDVR0PDAxLZXlBZ3JlZW1lbnQxDDAKBgNVBAoMA0lCTTEL\nMAkGA1UECAwCQVUwXDANBgkqhkiG9w0BAQEFAANLADBIAkEAwY9eVEdOobp  T646S\nsn7QmcxLeoWnCIulyP3hKR2f4E8Cy3FdO/j3HlrlKxJijB8eBDmdB0zR8CnVUipU\ncknj4QIDAQABMA0GCSqGSIb3DQEBCwUAA4IBAQAcYmkbcznF  fOm9bDuIeXHzNSus\nEwOhAberTXWvPMtjbDTmbVH5dRPU+DmgS+LEl2jhYC414R89EUApjrXmk1PzlBrN\nXEnBf9+OHOHOH7H4AIni3diw9PRzEdW5ENHUi  OIVoq7LxWP+RknSHGl8AfOghX/3\n6eRgtpIp+fTYwJkGdZaKb9cI5XXk0Eh1cZZ3W43PNsKbuv1BGLGjJVRRaswF9nb1\ng2M4iZLtVXltdkyHW/Z6TUWvG+  9+TYuKingixv0toaWyRGexjC1CeRORGhyYW8Dz\niGipRCWmVo97MC5sWtQjVAshB1TY6rUqipxzW9SqyjplBD+AHySY/IqGM+wU\n-----END CERTIFICATE-----\n",
    "CertificateType": "PEM",
    "CertificateUri":
    {
        "@odata.id": "/redfish/v1/Managers/bmc/NetworkProtocol/HTTPS/Certificates/1"
    }
}
```


**Install CA signed server certificate**

Replace server certificate using JSON file (above) with CA signed certificate details (certificate.json).

```
$ curl -c cjar -b cjar -k -H "X-Auth-Token: $bmc_token" -X POST https://${BMC_IP}/redfish/v1/CertificateService/Actions/CertificateService.ReplaceCertificate/ -d @certificate.json
{
  "@odata.context": "/redfish/v1/$metadata#Certificate.Certificate",
  "@odata.id": "/redfish/v1/Managers/bmc/NetworkProtocol/HTTPS/Certificates/1",
  "@odata.type": "#Certificate.v1_0_0.Certificate",
  "CertificateString": "-----BEGIN CERTIFICATE-----\nMIIC+TCCAeECCQCk+dNJDXfI1jANBgkqhkiG9w0BAQsFADCBmDELMAkGA1UEBhMC\nSU4xDjAMBgNVBAgMBURFTEhJMQ4wDAYDVQQHD  AVERUxISTEeMBwGA1UECgwVQ0VS\nVElGSUNBVEUgQVVUSE9SSVRZMQswCQYDVQQLDAJJVDEeMBwGA1UEAwwVRGF0YSBD\nZW50ZXIgT3ZlcmxvcmRzMRwwGg  YJKoZIhvcNAQkBFg1ub25lQG5vbmUuY29tMB4X\nDTE5MDYyNzExMTczNloXDTIwMTEwODExMTczNlowgasxJTAjBgNVHREMHHdzYm1j\nMDE1LmF1cy5zdGd  sYWJzLmlibS5jb20xDzANBgNVBAcMBkF1c3RpbjESMBAGA1UE\nAwwJOS4zLjIxLjU1MQ8wDQYDVQQpDAZteW5hbWUxCzAJBgNVBAYTAlVTMQ0wCwYE\nKw4D  AgwDUlNBMRUwEwYDVR0PDAxLZXlBZ3JlZW1lbnQxDDAKBgNVBAoMA0lCTTEL\nMAkGA1UECAwCQVUwXDANBgkqhkiG9w0BAQEFAANLADBIAkEAwY9eVEdOobp  T646S\nsn7QmcxLeoWnCIulyP3hKR2f4E8Cy3FdO/j3HlrlKxJijB8eBDmdB0zR8CnVUipU\ncknj4QIDAQABMA0GCSqGSIb3DQEBCwUAA4IBAQAcYmkbcznF  fOm9bDuIeXHzNSus\nEwOhAberTXWvPMtjbDTmbVH5dRPU+DmgS+LEl2jhYC414R89EUApjrXmk1PzlBrN\nXEnBf9+OHOHOH7H4AIni3diw9PRzEdW5ENHUi  OIVoq7LxWP+RknSHGl8AfOghX/3\n6eRgtpIp+fTYwJkGdZaKb9cI5XXk0Eh1cZZ3W43PNsKbuv1BGLGjJVRRaswF9nb1\ng2M4iZLtVXltdkyHW/Z6TUWvG+  9+TYuKingixv0toaWyRGexjC1CeRORGhyYW8Dz\niGipRCWmVo97MC5sWtQjVAshB1TY6rUqipxzW9SqyjplBD+AHySY/IqGM+wU\n-----END CERTIFICATE-----\n",
  "Description": "HTTPS certificate",
  "Id": "1",
  "Issuer": {
    "City": "DELHI",
    "CommonName": "Data Center Overlords",
    "Country": "IN",
    "Organization": "CERTIFICATE AUTHORITY",
    "OrganizationalUnit": "IT",
    "State": "DELHI"
  },
  "KeyUsage": [],
  "Name": "HTTPS certificate",
  "Subject": {
    "City": "Austin",
    "CommonName": "9.3.111.222",
    "Country": "US",
    "Organization": "IBM",
    "State": "AU"
  },
  "ValidNotAfter": "2020-11-07T23:17:36+00:00",
  "ValidNotBefore": "2019-06-26T23:17:36+00:00"
}
```
