import glob
import sys

from cffi import FFI

ffibuilder = FFI()
ffibuilder.cdef(
    """
typedef struct {
    /* I:   Input signal sampling rate in Hertz; 8000/12000/16000/24000                     */
    int API_sampleRate;
    /* I:   Maximum internal sampling rate in Hertz; 8000/12000/16000/24000                 */
    int maxInternalSampleRate;
    /* I:   Number of samples per packet; must be equivalent of 20, 40, 60, 80 or 100 ms    */
    int packetSize;
    /* I:   Bitrate during active speech in bits/second; internally limited                 */
    int bitRate;                        
    /* I:   Uplink packet loss in percent (0-100)                                           */
    int packetLossPercentage;
    
    /* I:   Complexity mode; 0 is lowest; 1 is medium and 2 is highest complexity           */
    int complexity;
    /* I:   Flag to enable in-band Forward Error Correction (FEC); 0/1                      */
    int useInBandFEC;
    /* I:   Flag to enable discontinuous transmission (DTX); 0/1                            */
    int useDTX;
} SKP_SILK_SDK_EncControlStruct;
typedef struct {
    /* I:   Output signal sampling rate in Hertz; 8000/12000/16000/24000                    */
    int API_sampleRate;
    /* O:   Number of samples per frame                                                     */
    int frameSize;
    /* O:   Frames per packet 1, 2, 3, 4, 5                                                 */
    int framesPerPacket;
    /* O:   Flag to indicate that the decoder has remaining payloads internally             */
    int moreInternalDecoderFrames;
    /* O:   Distance between main payload and redundant payload in packets                  */
    int inBandFECOffset;
} SKP_SILK_SDK_DecControlStruct;
int32_t SKP_Silk_SDK_Get_Encoder_Size(int32_t *encSizeBytes);
int32_t SKP_Silk_SDK_InitEncoder(void *encState, SKP_SILK_SDK_EncControlStruct *encStatus);
int32_t SKP_Silk_SDK_Encode(void *encState,
                            const SKP_SILK_SDK_EncControlStruct *encControl,
                            const int16_t *samplesIn,
                            int32_t nSamplesIn,
                            uint8_t *outData,
                            int16_t *nBytesOut);
int32_t SKP_Silk_SDK_Get_Decoder_Size(int32_t *decSizeBytes);
int32_t SKP_Silk_SDK_InitDecoder(void *decState);
int32_t SKP_Silk_SDK_Decode(void * decState,
                            SKP_SILK_SDK_DecControlStruct *decControl,
                            int32_t lostFlag,
                            const uint8_t *inData,
                            const int32_t nBytesIn,
                            int16_t *samplesOut,
                            int16_t *nSamplesOut);
uint8_t is_le();
int16_t swap_i16(int16_t data);
int SHOULD_SWAP();
void *PyMem_Malloc(size_t n);
void PyMem_Free(void* p);
    """
)

source = """
#include "SKP_Silk_typedef.h"
#include "SKP_Silk_SDK_API.h"
#include "SKP_Silk_control.h"
uint8_t is_le()
{
    uint16_t data=1;
    return *(uint8_t*)&data;
}
#ifdef _WIN32
    #define swap_i16 _byteswap_ushort
#else
    #define swap_i16 __builtin_bswap16
#endif /* _WIN32 */
#ifdef WORDS_BIGENDIAN
    #define SHOULD_SWAP() 1
#else
    #define SHOULD_SWAP() 0
#endif
"""
macro_base = []
if sys.byteorder != "little":
    macro_base.append(("WORDS_BIGENDIAN", None))
ffibuilder.set_source(
    "pysilk.backends.cffi._silk",
    source,
    sources=glob.glob("./silk-v3-decoder/silk/src/*.c"),
    include_dirs=["./silk-v3-decoder/silk/interface"],
    define_macros=macro_base,
)

if __name__ == "__main__":
    ffibuilder.compile()
