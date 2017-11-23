
r"""
Signature description in error log corresponding to error injection.
"""

DES_MCA_RECV1 = "'MCACALFIR[^0].*A MBA recoverable error'"
DES_MCA_RECV32 = "'MCACALFIR[^2].*Excessive refreshes'"
DES_MCA_UE = "'MCACALFIR[^10].*State machine'"


DES_MCS_RECV1 = "'MCFIR[^0].*mc internal recoverable'"
DES_MCS_UE = "'MCFIR[^1].*mc internal non recovervabl'"

DES_NX_RECV1 = "'NXDMAENGFIR[^13].*Channel 4 GZIP ECC PE'"
DES_NX_RECV32 = "'NXDMAENGFIR[^4].*Channel 0 842 engine ECC'"
DES_NX_UE = "'NXDMAENGFIR[^5].*Channel 0 842 engine ECC'"

DES_OBUS_RECV32 = "'OB_LFIR[^0].*CFIR internal parity error'"

DES_CXA_RECV5 = "'CXAFIR[^34].*CXA CE on data received'"
DES_CXA_RECV32 = "'CXAFIR[^2].*CXA CE on Master array'"
DES_CXA_UE = "'CXAFIR[^1].*CXA System Xstop PE'"

DES_NPU0_RECV32 = "'NPU0FIR[^13].*CQ CTL/SM ASBE Array single'"

DES_L2_RECV1 = "'L2FIR[^8].*L2 directory CE'"
DES_L2_RECV32 = "'L2FIR[^6].*L2 directory read CE'"
DES_L2_UE = "'L2FIR[^9].*L2 directory stuck bit CE'"

DES_L3_RECV1 = "'L3FIR[^17].*Received addr_error cresp'"
DES_L3_RECV32 = "'L3FIR[^7].*L3 cache write data CE'"
DES_L3_UE = "'L3FIR[^16].*addr_error cresp for mem'"

DES_OCC_RECV1 = "'OCCFIR[^45].*C405_ECC_CE'"
DES_CME_RECV1 = "'CMEFIR[^7].*PPE SRAM Uncorrectable Err'"
DES_EQ_RECV32 = "'EQ_LFIR[^1].*CFIR internal parity'"
DES_NCU_RECV1 = "'NCUFIR[^8].*NCU Store Queue Data'"

DES_CORE_RECV5 = "'COREFIR[^0].*IFU SRAM Recoverable err'"
DES_CORE_RECV1 = "'COREFIR[^30].*LSU Set Delete Err'"
DES_CORE_UE = "'COREFIR[^1].*TC Checkstop'"

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
             'NX_RECV1': ['02011100','0004000000000000', DES_NX_RECV1],
             'NX_UE': ['02011100','0400000000000000', DES_NX_UE],
             'NX_RECV32': ['02011100', '0800000000000000', DES_NX_RECV32],
             'CXA_RECV5': ['02010800', '0000000020000000', DES_CXA_RECV5],
             'CXA_RECV32': ['02010800', '2000000000000000', DES_CXA_RECV32],
             'CXA_UE': ['02010800', '4000000000000000', DES_CXA_UE],
             'OBUS_RECV32': ['0904000a', '8000000000000000', DES_OBUS_RECV32],
             'NPU0_RECV32': ['05013C00', '0004000000000000', DES_NPU0_RECV32],
             'L2FIR_RECV1': ['10010800', '0080000000000000', DES_L2_RECV1],
             'L2FIR_RECV32': ['10010800', '0200000000000000', DES_L2_RECV32],
             'L2FIR_UE': ['10010800', '0040000000000000', DES_L2_UE],
             'L3FIR_RECV1': ['10011800','0000400000000000', DES_L3_RECV1],
             'L3FIR_RECV32': ['10011800', '0100000000000000', DES_L3_RECV32],
             'L3FIR_UE': ['10011800', '0000800000000000', DES_L3_UE],
             'OCCFIR_RECV1': ['01010800', '0000000000040000', DES_OCC_RECV1],
             'CMEFIR_RECV1': ['10012000', '0100000000000000', DES_CME_RECV1],
             'EQFIR_RECV32': ['1004000A', '8000000000000000', DES_EQ_RECV32],
             'NCUFIR_RECV1': ['10011400', '0080000000000000', DES_NCU_RECV1],
             'COREFIR_RECV5': ['20010A40', '8000000000000000', DES_CORE_RECV5],
             'COREFIR_RECV1': ['20010A40', '0000000200000000', DES_CORE_RECV1],
             'COREFIR_UE': ['20010A40', '4000000000000000', DES_CORE_UE],

             }

# Address translation files
probe_cpu_file_path = '/root/probe_cpus.sh'
addr_translation_file_path = '/root/scom_addr_p9.sh'
