from . cimport control
cdef extern from "src/SKP_Silk_SDK_API.h":
    # Struct for TOC (Table of Contents)
    ctypedef struct SKP_Silk_TOC_struct:
        int     framesInPacket                                   # Number of 20 ms frames in packet
        int     fs_kHz                                           # Sampling frequency in packet
        int     inbandLBRR                                       # Does packet contain LBRR information
        int     corrupt                                          # Packet is corrupt
        int     vadFlags[5] # VAD flag for each frame in packet  # VAD flag for each frame in packet
        int     sigtypeFlags[5]                                  # Signal type for each frame in packet

    # Encoder functions

    # Get size in bytes of the Silk encoder state
    int SKP_Silk_SDK_Get_Encoder_Size(int* encSizeBytes)  # O:Number of bytes in SILK encoder state

    # Init or reset encoder
    int SKP_Silk_SDK_InitEncoder(
        void* encState,   # I/O: State
        control.SKP_SILK_SDK_EncControlStruct* encStatus)  # O:Encoder Status

    # Read control structure from encoder
    int SKP_Silk_SDK_QueryEncoder(
        const void* encState,                              # I:State
        control.SKP_SILK_SDK_EncControlStruct* encStatus)  # O:Encoder Status

    # Encode frame with Silk
    int SKP_Silk_SDK_Encode(
        void* encState,                                            # I/O: State
        const control.SKP_SILK_SDK_EncControlStruct* encControl,   # I:   Control status
        const short* samplesIn,                                    # I:   Speech sample input vector
        int nSamplesIn,                                            # I:   Number of samples in input vector
        unsigned char* outData,                                    # O:   Encoded output vector
        short* nBytesOut)                                          # I/O: Number of bytes in outData (input: Max bytes)

    # Decoder functions

    # Get size in bytes of the Silk decoder state
    int SKP_Silk_SDK_Get_Decoder_Size(int* decSizeBytes)           # O:   Number of bytes in SILK decoder state

    # Init or Reset decoder
    int SKP_Silk_SDK_InitDecoder(void* decState)                   # I/O: State

    # Decode a frame
    int SKP_Silk_SDK_Decode(
        void* decState,                                         # I/O: State
        control.SKP_SILK_SDK_DecControlStruct* decControl,      # I/O: Control Structure
        int lostFlag,                                           # I:   0: no loss, 1 loss
        const unsigned char* inData,                            # I:   Encoded input vector
        const int nBytesIn,                                     # I:   Number of input bytes
        short* samplesOut,                                      # O:   Decoded output speech vector
        short* nSamplesOut)                                     # I/O: Number of samples (vector/decoded)

    # Find Low Bit Rate Redundancy (LBRR) information in a packet
    void SKP_Silk_SDK_search_for_LBRR(
        const unsigned char* inData,        # I:   Encoded input vector
        const int nBytesIn,                 # I:   Number of input Bytes
        int lost_offset,                    # I:   Offset from lost packet
        unsigned char* LBRRData,            # O:   LBRR payload
        short* nLBRRBytes)                  # O:   Number of LBRR Bytes

    # Get table of contents for a packet
    void SKP_Silk_SDK_get_TOC(
        const unsigned char* inData,        # I:   Encoded input vector
        const int nBytesIn,                 # I:   Number of input bytes
        SKP_Silk_TOC_struct* Silk_TOC)      # O:   Table of contents

    #  Get the version number
    # Return a pointer to string specifying the version
    const char *SKP_Silk_SDK_get_version()
    # todo 继续写