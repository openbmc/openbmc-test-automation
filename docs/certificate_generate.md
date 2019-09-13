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
Organization Name (eg, company) [Default Company Ltd]:XYZ
Organizational Unit Name (eg, section) []:IT
Common Name (eg, YOUR name) []:XYZ CERTIFICATE AUTHORITY
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
    "CommonName": "xx.xx.xx.xx",
    "Country": "US",
    "Organization": "ABC Limited",
    "OrganizationalUnit": "IT",
    "State": "AU",
    "KeyPairAlgorithm": "RSA"
}
```

2. Generate CSR request using the following Redfish command.

```
$ curl -c cjar -b cjar -k -H "X-Auth-Token: $bmc_token" -X POST https://${BMC_IP}/redfish/v1/CertificateService/Actions/CertificateService.GenerateCSR/ -d @csr_file.json
{
  "CSRString": "-----BEGIN CERTIFICATE REQUEST-----\nMIICyzCCAbMCAQEwgYUxDzANBgNVBAcMBkF1c3RpbjEUMBIGA1UEAwwLeHgueHgu\neHgueHgxCzAJBgNVBAYTAlVTMQ0wCwYEKw4DAgwDUlNBMR0wGwYDVR0lDBRTZXJ2\nZXJBdXRoZW50aWNhdGlvbjEUMBIGA1UECgwLQUJDIExpbWl0ZWQxCzAJBgNVBAgM\nAkFVMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA7+OoXRmAI85W/5pB\nYjC5EdZ/atrPpkIxjT4sXANZLXm6/vkfR/BAxd5s8DYrifPjdfvJRv33cAPT6+pe\no/t793hdBx7Cwwzqlj3czfdbpvGp90I7BQ1OvKCo/NDmqeTm+5jphYpd8ZvKmBNC\nOfHV0sr3/dMPHME16aunDEHFJz1CzXpG5kSszRYbwcZrXC7rvmSi8UBX8BYoKWzx\nlAGdOYh9j5k/LVNQuKFJjqIfesYJ8fajgsJr8bj81o+bOzvG+zApvt+Ak8B8fqa7\nvET4jb1oeDuSi9D1/Xax+2qx3vInIQOOZz3OCVjxNLZMWOA+P86z59e/6YkXOg/Q\nkXG4uQIDAQABoAAwDQYJKoZIhvcNAQELBQADggEBAOTLICzJiYerbWa6VyXv/w8b\nr160bNDvIRXJf8E2b5+27NinZb+65WVa6oxE9Ai7UEN+mHkbnDpb2vujp/wuROER\nrgmjstePJST+EqX5PuoSxbPhE0ucHw7dTZf9agfvNLlpgTUo/Lv9A2pCSDa5KZ13\nu96AFsFBjBuanUK2k7aoEc/Rl7JhfxUaXNszzYqDgwIHggYWbZO7Ku7HHbY1qYGR\nD0XaLUyXAxgB76mcud004zu7swTJxDlM+c5+i0yqflWQiVWEAOW9HDeHvnYmShuT\n+HS1vhv+x/9HDHowxiWOt2Th18uzdf+F0446fR8uoIrG1z7KdNoxipUnVKfyXTg=\n-----END CERTIFICATE REQUEST-----\n",
  "CertificateCollection": {
    "@odata.id": "/redfish/v1/Managers/bmc/NetworkProtocol/HTTPS/Certificates/"
  }
```

3. Convert response into .csr file (device.csr)

```
$ cat device.csr
-----BEGIN CERTIFICATE REQUEST-----
MIICyzCCAbMCAQEwgYUxDzANBgNVBAcMBkF1c3RpbjEUMBIGA1UEAwwLeHgueHgu
eHgueHgxCzAJBgNVBAYTAlVTMQ0wCwYEKw4DAgwDUlNBMR0wGwYDVR0lDBRTZXJ2
ZXJBdXRoZW50aWNhdGlvbjEUMBIGA1UECgwLQUJDIExpbWl0ZWQxCzAJBgNVBAgM
AkFVMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA7+OoXRmAI85W/5pB
YjC5EdZ/atrPpkIxjT4sXANZLXm6/vkfR/BAxd5s8DYrifPjdfvJRv33cAPT6+pe
o/t793hdBx7Cwwzqlj3czfdbpvGp90I7BQ1OvKCo/NDmqeTm+5jphYpd8ZvKmBNC
OfHV0sr3/dMPHME16aunDEHFJz1CzXpG5kSszRYbwcZrXC7rvmSi8UBX8BYoKWzx
lAGdOYh9j5k/LVNQuKFJjqIfesYJ8fajgsJr8bj81o+bOzvG+zApvt+Ak8B8fqa7
vET4jb1oeDuSi9D1/Xax+2qx3vInIQOOZz3OCVjxNLZMWOA+P86z59e/6YkXOg/Q
kXG4uQIDAQABoAAwDQYJKoZIhvcNAQELBQADggEBAOTLICzJiYerbWa6VyXv/w8b
r160bNDvIRXJf8E2b5+27NinZb+65WVa6oxE9Ai7UEN+mHkbnDpb2vujp/wuROER
rgmjstePJST+EqX5PuoSxbPhE0ucHw7dTZf9agfvNLlpgTUo/Lv9A2pCSDa5KZ13
u96AFsFBjBuanUK2k7aoEc/Rl7JhfxUaXNszzYqDgwIHggYWbZO7Ku7HHbY1qYGR
D0XaLUyXAxgB76mcud004zu7swTJxDlM+c5+i0yqflWQiVWEAOW9HDeHvnYmShuT
+HS1vhv+x/9HDHowxiWOt2Th18uzdf+F0446fR8uoIrG1z7KdNoxipUnVKfyXTg=
-----END CERTIFICATE REQUEST-----
```

**Create CA signed server certificate using CSR request**

1. Use BMC generated CSR request (device.csr) to generate CA signed certificate (device.crt).
```
openssl x509 -req -in device.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out device.crt -days 500 -sha256
```
Note: You will be prompted to give a password for private key.


2. Create JSON file (certificate.json) with the device.crt file created in step 1.

```
$ cat certificate.json
{
    "CertificateString": "-----BEGIN CERTIFICATE-----\nMIIDkTCCAnkCCQD7oPxudsyOjTANBgkqhkiG9w0BAQsFADCBjjELMAkGA1UEBhMC\nVVMxDzANBgNVBAgMBk9yZWdvbjERMA8GA1UEBwwIUG9ydGxhbmQxDDAKBgNVBAoM\nA1hZWjELMAkGA1UECwwCSVQxIjAgBgNVBAMMGVhZWiBDRVJUSUZJQ0FURSBBVVRI\nT1JJVFkxHDAaBgkqhkiG9w0BCQEWDW5vbmVAbm9uZS5jb20wHhcNMTkwOTEyMDkx\nMzQwWhcNMjEwMTI0MDkxMzQwWjCBhTEPMA0GA1UEBwwGQXVzdGluMRQwEgYDVQQD\nDAt4eC54eC54eC54eDELMAkGA1UEBhMCVVMxDTALBgQrDgMCDANSU0ExHTAbBgNV\nHSUMFFNlcnZlckF1dGhlbnRpY2F0aW9uMRQwEgYDVQQKDAtBQkMgTGltaXRlZDEL\nMAkGA1UECAwCQVUwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDv46hd\nGYAjzlb/mkFiMLkR1n9q2s+mQjGNPixcA1ktebr++R9H8EDF3mzwNiuJ8+N1+8lG\n/fdwA9Pr6l6j+3v3eF0HHsLDDOqWPdzN91um8an3QjsFDU68oKj80Oap5Ob7mOmF\nil3xm8qYE0I58dXSyvf90w8cwTXpq6cMQcUnPULNekbmRKzNFhvBxmtcLuu+ZKLx\nQFfwFigpbPGUAZ05iH2PmT8tU1C4oUmOoh96xgnx9qOCwmvxuPzWj5s7O8b7MCm+\n34CTwHx+pru8RPiNvWh4O5KL0PX9drH7arHe8ichA45nPc4JWPE0tkxY4D4/zrPn\n17/piRc6D9CRcbi5AgMBAAEwDQYJKoZIhvcNAQELBQADggEBAJ+xLxyfBBpRXov/\noRVMyJSWRSSITfzvcZVMcbDXAWR591rdYPNmpmpuDSdtynIvJe33H9FyXRI1UMnw\n5BYpJrVjxxyEvIyoxbJSkLxjkO6TUJNI2w7wBJeUDpwdYWuwmUc6UfO5c5LGSb4z\nzbvfEdSsW+3pHuFopuhU8d/SR14rjZiGpU2MBF+/yEyUXmQ5jIU69UwvIvbch0Zy\naquTL4O3aL1Lc9ACVUsQ7mTUS+niduIsZLvvI+OWMShRo8CEUJl9BKijQJhwvUVf\nUBNa1pVzonLxdt3eRTv93X4cu5ole6wO2DA19PWnlt/16XYw61/5naYckslQTRdc\nGvsIpb0=\n-----END CERTIFICATE-----",
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
  "CertificateString": "-----BEGIN CERTIFICATE-----\nMIIDkTCCAnkCCQD7oPxudsyOjTANBgkqhkiG9w0BAQsFADCBjjELMAkGA1UEBhMC\nVVMxDzANBgNVBAgMBk9yZWdvbjERMA8GA1UEBwwIUG9ydGxhbmQxDDAKBgNVBAoM\nA1hZWjELMAkGA1UECwwCSVQxIjAgBgNVBAMMGVhZWiBDRVJUSUZJQ0FURSBBVVRI\nT1JJVFkxHDAaBgkqhkiG9w0BCQEWDW5vbmVAbm9uZS5jb20wHhcNMTkwOTEyMDkx\nMzQwWhcNMjEwMTI0MDkxMzQwWjCBhTEPMA0GA1UEBwwGQXVzdGluMRQwEgYDVQQD\nDAt4eC54eC54eC54eDELMAkGA1UEBhMCVVMxDTALBgQrDgMCDANSU0ExHTAbBgNV\nHSUMFFNlcnZlckF1dGhlbnRpY2F0aW9uMRQwEgYDVQQKDAtBQkMgTGltaXRlZDEL\nMAkGA1UECAwCQVUwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDv46hd\nGYAjzlb/mkFiMLkR1n9q2s+mQjGNPixcA1ktebr++R9H8EDF3mzwNiuJ8+N1+8lG\n/fdwA9Pr6l6j+3v3eF0HHsLDDOqWPdzN91um8an3QjsFDU68oKj80Oap5Ob7mOmF\nil3xm8qYE0I58dXSyvf90w8cwTXpq6cMQcUnPULNekbmRKzNFhvBxmtcLuu+ZKLx\nQFfwFigpbPGUAZ05iH2PmT8tU1C4oUmOoh96xgnx9qOCwmvxuPzWj5s7O8b7MCm+\n34CTwHx+pru8RPiNvWh4O5KL0PX9drH7arHe8ichA45nPc4JWPE0tkxY4D4/zrPn\n17/piRc6D9CRcbi5AgMBAAEwDQYJKoZIhvcNAQELBQADggEBAJ+xLxyfBBpRXov/\noRVMyJSWRSSITfzvcZVMcbDXAWR591rdYPNmpmpuDSdtynIvJe33H9FyXRI1UMnw\n5BYpJrVjxxyEvIyoxbJSkLxjkO6TUJNI2w7wBJeUDpwdYWuwmUc6UfO5c5LGSb4z\nzbvfEdSsW+3pHuFopuhU8d/SR14rjZiGpU2MBF+/yEyUXmQ5jIU69UwvIvbch0Zy\naquTL4O3aL1Lc9ACVUsQ7mTUS+niduIsZLvvI+OWMShRo8CEUJl9BKijQJhwvUVf\nUBNa1pVzonLxdt3eRTv93X4cu5ole6wO2DA19PWnlt/16XYw61/5naYckslQTRdc\nGvsIpb0=\n-----END CERTIFICATE-----\n",
  "Description": "HTTPS certificate",
  "Id": "1",
  "Issuer": {
    "City": "Portland",
    "CommonName": "XYZ CERTIFICATE AUTHORITY",
    "Country": "US",
    "Organization": "XYZ",
    "OrganizationalUnit": "IT",
    "State": "Oregon"
  },
  "KeyUsage": [],
  "Name": "HTTPS certificate",
  "Subject": {
    "City": "Austin",
    "CommonName": "xx.xx.xx.xx",
    "Country": "US",
    "Organization": "ABC Limited",
    "State": "AU"
  },
  "ValidNotAfter": "2021-01-23T21:13:40+00:00",
  "ValidNotBefore": "2019-09-11T21:13:40+00:00"
}
```
