#!/usr/bin/env python3

"""
Network related utility functions.

Python utility to compare IPv4/IPv6 addresses or hostnames
and determine if they're in the same network segment with
automatic subnet detection.

"""

import socket
from ipaddress import ip_address, ip_network, IPv4Address, IPv6Address


def get_network_info(ip_version=4):
    """
    Get system's IP and infer network configuration.

    Args:
        ip_version: 4 for IPv4, 6 for IPv6

    Returns:
        Tuple of (system_ip, subnet_cidr)
    """
    try:
        if ip_version == 4:
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.connect(("8.8.8.8", 80))
        else:
            s = socket.socket(socket.AF_INET6, socket.SOCK_DGRAM)
            s.connect(("2001:4860:4860::8888", 80))

        system_ip = s.getsockname()[0]
        s.close()

        return system_ip, "/24" if ip_version == 4 else "/64"

    except Exception as e:
        print(f"Exception: {e}")
        return None, "/24" if ip_version == 4 else "/64"


def resolve_host_to_ip(host):
    """
    Resolve hostname or IP address to IP string.
    Handles both IPv4 and IPv6.

    Args:
        host: IP address or hostname

    Returns:
        Resolved IP address as string

    Raises:
        ValueError: If hostname cannot be resolved
    """
    host = host.strip()

    # Try to parse as IP address first
    try:
        ip_address(host)
        return host
    except ValueError as e:
        print(f"Error: {e}")
        pass

    # Try IPv4 resolution
    try:
        return socket.gethostbyname(host)
    except socket.gaierror as e:
        print(f"Error: {e}")
        pass

    # Try IPv6 resolution
    try:
        result = socket.getaddrinfo(host, None, socket.AF_INET6)
        if result:
            return result[0][4][0]
    except socket.gaierror as e:
        print(f"Error: {e}")
        pass

    raise ValueError(f"Cannot resolve hostname: {host}")


def check_ip_in_system_subnet(target, system_ip, prefix):
    """
    Check if target IP is in the same subnet as system IP with given prefix.

    Args:
        target: IPv4Address or IPv6Address object
        system_ip: Local IP address string
        prefix: Subnet prefix length

    Returns:
        True if target is in same subnet, False otherwise
    """
    try:
        system_net = ip_network(f"{system_ip}/{prefix}", strict=False)
        return target in system_net
    except Exception as e:
        print(f"Exception: {e}")
        return False


def get_subnet_mask_for_ip(target_ip):
    """
    Determine subnet mask for given IP (IPv4 or IPv6).
    Unified function handling both IP versions.

    Args:
        target_ip: IP address string

    Returns:
        Subnet mask in CIDR notation
        - IPv4: "/8" (loopback), "/16" (large private), "/24" (default)
        - IPv6: "/128" (loopback), "/64" (default)
    """
    try:
        target = ip_address(target_ip)

        # Handle IPv4
        if isinstance(target, IPv4Address):
            # Loopback: 127.0.0.0/8
            if target.is_loopback:
                return "/8"

            # Private addresses: check network
            if target.is_private:
                system_ip, _ = get_network_info(4)

                if system_ip:
                    # Check /24 first (most common)
                    if check_ip_in_system_subnet(target, system_ip, 24):
                        return "/24"

                    # Check /16 for larger networks
                    if check_ip_in_system_subnet(target, system_ip, 16):
                        return "/16"

                return "/24"

            # Public addresses
            return "/24"

        # Handle IPv6
        elif isinstance(target, IPv6Address):
            # Loopback: ::1/128
            if target.is_loopback:
                return "/128"

            # Link-local: fe80::/10 or Private: fc00::/7
            if target.is_link_local or target.is_private:
                return "/64"

            # Global unicast
            return "/64"

        return "/24"

    except Exception as e:
        print(f"Exception: {e}")
        return "/24"


def are_in_same_network(host1, host2):
    """
    Check if two IPs or hostnames are in the same network.

    Supports:
    - IPv4 addresses (e.g., "192.168.1.10")
    - IPv6 addresses (e.g., "2001:db8::1")
    - Hostnames (e.g., "localhost", "google.com")
    - Mixed input with whitespace

    Args:
        host1: First IP or hostname (IPv4/IPv6)
        host2: Second IP or hostname (IPv4/IPv6)

    Returns:
        True if same network, False if different network
    """
    try:
        # Resolve both hosts to IPs
        ip1 = resolve_host_to_ip(host1)
        ip2 = resolve_host_to_ip(host2)

        # Parse IP addresses
        addr1 = ip_address(ip1)
        addr2 = ip_address(ip2)

        # Check if both are same IP version using isinstance
        is_ipv4_pair = isinstance(addr1, IPv4Address) and isinstance(
            addr2, IPv4Address
        )
        is_ipv6_pair = isinstance(addr1, IPv6Address) and isinstance(
            addr2, IPv6Address
        )

        if not (is_ipv4_pair or is_ipv6_pair):
            # Different IP versions (IPv4 vs IPv6) cannot be in same network
            return False

        # Auto-detect subnet masks
        cidr1 = get_subnet_mask_for_ip(ip1)
        cidr2 = get_subnet_mask_for_ip(ip2)

        # Select the more specific subnet mask (larger CIDR prefix) for
        # precise network comparison
        # Example:
        #    IPv4: /24 over /8 (192.168.1.0/24 vs 10.0.0.0/8)
        #    IPv6: /128 over /64
        cidr = cidr1 if int(cidr1[1:]) >= int(cidr2[1:]) else cidr2

        # Compare network addresses
        net1 = ip_network(f"{ip1}{cidr}", strict=False)
        net2 = ip_network(f"{ip2}{cidr}", strict=False)

        return net1.network_address == net2.network_address

    except Exception as e:
        print(f"Exception: {e}")
        return False
