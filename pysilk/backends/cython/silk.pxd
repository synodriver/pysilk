# cython: language_level=3
# cython: cdivision=True
from libc.stdint cimport int16_t, int32_t, uint8_t


cdef extern from "SKP_Silk_control.h" nogil:
    ctypedef struct SKP_SILK_SDK_EncControlStruct:
        int32_t API_sampleRate
        int32_t maxInternalSampleRate
        int32_t packetSize
        int32_t bitRate
        int32_t packetLossPercentage
        int32_t complexity
        int32_t useInBandFEC
        int32_t useDTX
    ctypedef struct SKP_SILK_SDK_DecControlStruct:
        int32_t API_sampleRate
        int32_t frameSize
        int32_t framesPerPacket
        int32_t moreInternalDecoderFrames
        int32_t inBandFECOffset


cdef extern  from "SKP_Silk_SDK_API.h" nogil:
    int32_t SKP_Silk_SDK_Get_Encoder_Size(int32_t *encSizeBytes)
    int32_t SKP_Silk_SDK_InitEncoder(void *encState, SKP_SILK_SDK_EncControlStruct *encStatus)
    int32_t SKP_Silk_SDK_Encode(void *encState,
                                const SKP_SILK_SDK_EncControlStruct *encControl,
                                const int16_t *samplesIn,
                                int32_t nSamplesIn,
                                uint8_t *outData,
                                int16_t *nBytesOut)
    int32_t SKP_Silk_SDK_Get_Decoder_Size(int32_t *decSizeBytes)
    int32_t SKP_Silk_SDK_InitDecoder(void *decState)
    int32_t SKP_Silk_SDK_Decode(void * decState,
                                SKP_SILK_SDK_DecControlStruct *decControl,
                                int32_t lostFlag,
                                const uint8_t *inData,
                                const int32_t nBytesIn,
                                int16_t *samplesOut,
                                int16_t *nSamplesOut)

cdef extern  from * nogil:
    """
/*
void swap_i16(int16_t *data)
{
    int8_t *p = (int8_t *)data;
    int8_t tmp = p[0];
    p[0] = p[1];
    p[1] = tmp;
}
*/
uint8_t is_le()
{
    uint16_t data=1;
    return *(uint8_t*)&data;
}
#if defined(_WIN64) || defined(_WIN32)
    #define swap_i16 _byteswap_ushort
#else
    #define swap_i16 __builtin_bswap16
#endif /* _WIN32 */
#ifdef WORDS_BIGENDIAN
    #define SHOULD_SWAP 1
#else
    #define SHOULD_SWAP 0
#endif
    """
    int16_t swap_i16(int16_t data)
    uint8_t is_le()
    int SHOULD_SWAP
