#!/usr/bin/env python3

r"""
Provide certificate generation utilities for mTLS authentication testing.
"""

import datetime

from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.x509.oid import ExtendedKeyUsageOID, NameOID

# https://oidref.com/1.3.6.1.4.1.311.20.2.3
UPN_OID = "1.3.6.1.4.1.311.20.2.3"


def generate_ca(
    common_name="Test CA",
):
    r"""
    Generate a self-signed CA certificate and private key.

    Description of argument(s):
    common_name    Common Name for the CA certificate subject.

    Returns a tuple of (ca_cert_pem, ca_key_pem) as strings.
    """

    private_key = ec.generate_private_key(ec.SECP256R1())
    name = x509.Name(
        [
            x509.NameAttribute(NameOID.ORGANIZATION_NAME, "OpenBMC"),
            x509.NameAttribute(NameOID.ORGANIZATIONAL_UNIT_NAME, "Test"),
            x509.NameAttribute(NameOID.COMMON_NAME, common_name),
        ]
    )
    builder = (
        x509.CertificateBuilder()
        .subject_name(name)
        .issuer_name(name)
        .public_key(private_key.public_key())
        .serial_number(x509.random_serial_number())
        .not_valid_before(
            datetime.datetime(1970, 1, 1, tzinfo=datetime.timezone.utc)
        )
        .not_valid_after(
            datetime.datetime(2070, 1, 1, tzinfo=datetime.timezone.utc)
        )
        .add_extension(
            x509.BasicConstraints(ca=True, path_length=None),
            critical=True,
        )
        .add_extension(
            x509.KeyUsage(
                digital_signature=False,
                content_commitment=False,
                key_encipherment=False,
                data_encipherment=False,
                key_agreement=False,
                key_cert_sign=True,
                crl_sign=True,
                encipher_only=False,
                decipher_only=False,
            ),
            critical=False,
        )
    )
    cert = builder.sign(private_key, hashes.SHA256())

    return _encode_cert_and_key(cert, private_key)


def generate_client_cert(
    ca_cert_pem,
    ca_key_pem,
    common_name=None,
    upn=None,
    not_valid_before=None,
    not_valid_after=None,
    extended_key_usage=None,
):
    r"""
    Generate a client certificate signed by the given CA.

    Description of argument(s):
    ca_cert_pem        PEM-encoded CA certificate string.
    ca_key_pem         PEM-encoded CA private key string.
    common_name        Common Name for the client cert subject.
                       None to omit CN.
    upn                User Principal Name for SAN OtherName.
                       None to omit UPN.
    not_valid_before   Datetime string in format
                       "YYYY-MM-DD HH:MM:SS" or None for default.
    not_valid_after    Datetime string in format
                       "YYYY-MM-DD HH:MM:SS" or None for default.
    extended_key_usage EKU type: "clientAuth", "serverAuth", or
                       None for default (clientAuth).

    Returns a tuple of (cert_pem, key_pem) as strings.
    """

    ca_cert = x509.load_pem_x509_certificate(ca_cert_pem.encode())
    ca_key = serialization.load_pem_private_key(ca_key_pem.encode(), None)

    private_key = ec.generate_private_key(ec.SECP256R1())
    cert_names = [
        x509.NameAttribute(NameOID.COUNTRY_NAME, "US"),
        x509.NameAttribute(NameOID.ORGANIZATION_NAME, "OpenBMC"),
        x509.NameAttribute(NameOID.ORGANIZATIONAL_UNIT_NAME, "Test"),
    ]
    if common_name is not None:
        cert_names.append(x509.NameAttribute(NameOID.COMMON_NAME, common_name))

    if not_valid_before is not None:
        nvb = datetime.datetime.strptime(
            not_valid_before, "%Y-%m-%d %H:%M:%S"
        ).replace(tzinfo=datetime.timezone.utc)
    else:
        nvb = datetime.datetime(1970, 1, 1, tzinfo=datetime.timezone.utc)

    if not_valid_after is not None:
        nva = datetime.datetime.strptime(
            not_valid_after, "%Y-%m-%d %H:%M:%S"
        ).replace(tzinfo=datetime.timezone.utc)
    else:
        nva = datetime.datetime(2070, 1, 1, tzinfo=datetime.timezone.utc)

    if extended_key_usage == "serverAuth":
        eku_list = [ExtendedKeyUsageOID.SERVER_AUTH]
    else:
        eku_list = [ExtendedKeyUsageOID.CLIENT_AUTH]

    builder = (
        x509.CertificateBuilder()
        .subject_name(x509.Name(cert_names))
        .issuer_name(ca_cert.subject)
        .public_key(private_key.public_key())
        .serial_number(x509.random_serial_number())
        .not_valid_before(nvb)
        .not_valid_after(nva)
        .add_extension(
            x509.KeyUsage(
                digital_signature=True,
                content_commitment=False,
                key_encipherment=False,
                data_encipherment=False,
                key_agreement=True,
                key_cert_sign=False,
                crl_sign=False,
                encipher_only=False,
                decipher_only=False,
            ),
            critical=False,
        )
        .add_extension(
            x509.ExtendedKeyUsage(eku_list),
            critical=True,
        )
    )

    if upn is not None:
        upn_der = _encode_utf8string_der(upn)
        builder = builder.add_extension(
            x509.SubjectAlternativeName(
                [
                    x509.OtherName(
                        x509.ObjectIdentifier(UPN_OID),
                        upn_der,
                    )
                ]
            ),
            critical=False,
        )

    cert = builder.sign(ca_key, hashes.SHA256())

    return _encode_cert_and_key(cert, private_key)


def generate_intermediate_ca(
    ca_cert_pem,
    ca_key_pem,
):
    r"""
    Generate an intermediate CA certificate signed by the root CA.

    Description of argument(s):
    ca_cert_pem    PEM-encoded root CA certificate string.
    ca_key_pem     PEM-encoded root CA private key string.

    Returns a tuple of (cert_pem, key_pem) as strings.
    """

    ca_cert = x509.load_pem_x509_certificate(ca_cert_pem.encode())
    ca_key = serialization.load_pem_private_key(ca_key_pem.encode(), None)

    private_key = ec.generate_private_key(ec.SECP256R1())
    name = x509.Name(
        [
            x509.NameAttribute(NameOID.COUNTRY_NAME, "US"),
            x509.NameAttribute(NameOID.ORGANIZATION_NAME, "OpenBMC"),
            x509.NameAttribute(NameOID.ORGANIZATIONAL_UNIT_NAME, "Test"),
            x509.NameAttribute(NameOID.COMMON_NAME, "Test Intermediate CA"),
        ]
    )
    builder = (
        x509.CertificateBuilder()
        .subject_name(name)
        .issuer_name(ca_cert.subject)
        .public_key(private_key.public_key())
        .serial_number(x509.random_serial_number())
        .not_valid_before(
            datetime.datetime(1970, 1, 1, tzinfo=datetime.timezone.utc)
        )
        .not_valid_after(
            datetime.datetime(2070, 1, 1, tzinfo=datetime.timezone.utc)
        )
        .add_extension(
            x509.BasicConstraints(ca=True, path_length=0),
            critical=True,
        )
        .add_extension(
            x509.KeyUsage(
                digital_signature=False,
                content_commitment=False,
                key_encipherment=False,
                data_encipherment=False,
                key_agreement=False,
                key_cert_sign=True,
                crl_sign=True,
                encipher_only=False,
                decipher_only=False,
            ),
            critical=True,
        )
    )
    cert = builder.sign(ca_key, hashes.SHA256())

    return _encode_cert_and_key(cert, private_key)


def generate_self_signed_client_cert(
    common_name,
):
    r"""
    Generate a self-signed client certificate (not CA-signed).

    Description of argument(s):
    common_name    Common Name for the certificate subject.

    Returns a tuple of (cert_pem, key_pem) as strings.
    """

    private_key = ec.generate_private_key(ec.SECP256R1())
    name = x509.Name(
        [
            x509.NameAttribute(NameOID.COUNTRY_NAME, "US"),
            x509.NameAttribute(NameOID.ORGANIZATION_NAME, "OpenBMC"),
            x509.NameAttribute(NameOID.COMMON_NAME, common_name),
        ]
    )
    builder = (
        x509.CertificateBuilder()
        .subject_name(name)
        .issuer_name(name)
        .public_key(private_key.public_key())
        .serial_number(x509.random_serial_number())
        .not_valid_before(
            datetime.datetime(1970, 1, 1, tzinfo=datetime.timezone.utc)
        )
        .not_valid_after(
            datetime.datetime(2070, 1, 1, tzinfo=datetime.timezone.utc)
        )
        .add_extension(
            x509.ExtendedKeyUsage([ExtendedKeyUsageOID.CLIENT_AUTH]),
            critical=True,
        )
    )
    cert = builder.sign(private_key, hashes.SHA256())

    return _encode_cert_and_key(cert, private_key)


def write_cert_and_key(
    cert_pem,
    key_pem,
    cert_path,
    key_path,
):
    r"""
    Write PEM-encoded certificate and key to files.

    Description of argument(s):
    cert_pem     PEM-encoded certificate string.
    key_pem      PEM-encoded private key string.
    cert_path    File path to write the certificate.
    key_path     File path to write the private key.
    """

    with open(cert_path, "w") as f:
        f.write(cert_pem)
    with open(key_path, "w") as f:
        f.write(key_pem)


def _encode_cert_and_key(cert, private_key):
    r"""
    Encode certificate and key to PEM strings.

    Description of argument(s):
    cert           A cryptography x509.Certificate object.
    private_key    A cryptography private key object.

    Returns a tuple of (cert_pem, key_pem) as strings.
    """

    cert_pem = cert.public_bytes(serialization.Encoding.PEM).decode()
    key_pem = private_key.private_bytes(
        serialization.Encoding.PEM,
        serialization.PrivateFormat.TraditionalOpenSSL,
        serialization.NoEncryption(),
    ).decode()

    return cert_pem, key_pem


def _encode_utf8string_der(value):
    r"""
    Encode a string as ASN.1 DER UTF8String.

    Description of argument(s):
    value    The string to encode.

    Returns DER-encoded bytes (tag 0x0C + length + utf-8 data).
    """

    utf8_bytes = value.encode("utf-8")
    length = len(utf8_bytes)
    if length < 0x80:
        header = bytes([0x0C, length])
    else:
        len_bytes = length.to_bytes((length.bit_length() + 7) // 8, "big")
        header = bytes([0x0C, 0x80 | len(len_bytes)]) + len_bytes

    return header + utf8_bytes
