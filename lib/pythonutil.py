from socket import inet_ntoa
from struct import pack


def calcDottedNetmask(mask):
    bits = 0
    for i in xrange(32 - mask, 32):
        bits |= (1 << i)
    packed_value = pack('!I', bits)
    addr = inet_ntoa(packed_value)
    return addr
