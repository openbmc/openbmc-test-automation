
r"""
Signature description in error log corresponding to error injection.
"""

DES_MCA_RECV1 = "'mca.n0p0c0.*MCACALFIR[^0].*A MBA recoverable error'"
DES_MCA_RECV32 = "'mca.n0p0c0.*MCACALFIR[^2].*Excessive refreshes'"
DES_MCA_UE = "'mca.n0p0c0.*MCACALFIR[^10].*State machine'"


DES_MCS_RECV1 = "'mcs.n0p0c0.*MCFIR[^0].*mc internal recoverable'"
DES_MCS_UE = "'mcs.n0p0c0.*MCFIR[^1].*mc internal non recovervable'"


DES_NX_RECV1 = "'pu.n0p0.*NXDMAENGFIR[^5].*Channel 0 842 engine ECC'"
DES_NX_RECV32 = "'pu.n0p0.*NXDMAENGFIR[^4].*Channel 0 842 engine ECC'"

DES_OBUS_RECV32 = "'ob.n0p0c0.*OB_LFIR[^0].*CFIR internal parity error'"

DES_CXA_RECV5 = "'capp.n0p0c0.*CXAFIR[^34].*CXA CE on data received'"
DES_CXA_RECV32 = "'capp.n0p0c0.*CXAFIR[^2].*CXA CE on Master array'"

DES_NPU0_RECV32 = "'pu.n0p0.*NPU0FIR[^0].*NTL array CE'"

# The following is an error injection dictionary with each entry consisting of:
# - field_name: Targettype_threshold_limit .
#   - A list consisting of the following fields:
#     - field1: FIR (Fault isolation register) value.
#     - field2: chip address.
#     - field3: Error log signature description.

ERROR_INJECT_DICT = {'MCACALIFIR_RECV1': ['07010900', '8000000000000000',\
                                          DES_MCA_RECV1],
             'MCACALIFIR_RECV32': ['07010900', '2000000000000000', \
                                   DES_MCA_RECV32],
             'MCACALIFIR_UE': ['07010900', '0020000000000000', DES_MCA_UE],
             'MCS_RECV1': ['05010800', '8000000000000000', DES_MCS_RECV1],
             'MCS_UE': ['05010800', '4000000000000000', DES_MCS_UE],
             'NX_RECV1': ['02011100','0400000000000000', DES_NX_RECV1],
             'NX_RECV32': ['02011100', '0800000000000000', DES_NX_RECV32],
             'CXA_RECV5': ['02010800', '0000000020000000', DES_CXA_RECV5],
             'CXA_RECV32': ['02010800', '2000000000000000', DES_CXA_RECV32],
             'OBUS_RECV32': ['0904000a', '8000000000000000', DES_OBUS_RECV32],
             'NPU0_RECV32': ['05011400', '8000000000000000', DES_NPU0_RECV32]
             }

