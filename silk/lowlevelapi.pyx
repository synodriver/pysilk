# cython: language_level=3
from . cimport api
from . cimport control

def get_encoder_size():
    """Get size in bytes of the Silk encoder state"""
    cdef int decSizeBytes
    api.SKP_Silk_SDK_Get_Encoder_Size(&decSizeBytes)
    return decSizeBytes

def init_encoder(
                encState,int API_sampleRate,
                int maxInternalSampleRate,
                int packetSize,
                int bitRate,
                int packetLossPercentage,
                int complexity,
                int useInBandFEC,
                int useDTX):
    """Init or reset encoder"""
    api.SKP_Silk_SDK_InitEncoder()