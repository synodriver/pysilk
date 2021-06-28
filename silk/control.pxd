cdef extern from "SKP_Silk_control.h" nogil:
    ctypedef struct SKP_SILK_SDK_EncControlStruct:
        # I:   Input signal sampling rate in Hertz; 8000/12000/16000/24000
        int API_sampleRate

        # I:   Maximum internal sampling rate in Hertz; 8000/12000/16000/24000
        int maxInternalSampleRate

        # I:   Number of samples per packet; must be equivalent of 20, 40, 60, 80 or 100 ms
        int packetSize

        # I:   Bitrate during active speech in bits/second; internally limited
        int bitRate

        # I:   Uplink packet loss in percent (0-100)
        int packetLossPercentage

        # I:   Complexity mode; 0 is lowest; 1 is medium and 2 is highest complexity
        int complexity

        # I:   Flag to enable in-band Forward Error Correction (FEC); 0/1
        int useInBandFEC

        # I:   Flag to enable discontinuous transmission (DTX); 0/1
        int useDTX

    ctypedef struct SKP_SILK_SDK_DecControlStruct:
        # I:   Output signal sampling rate in Hertz; 8000/12000/16000/24000
        int API_sampleRate

        # O:   Number of samples per frame
        int frameSize

        # O:   Frames per packet 1, 2, 3, 4, 5
        int framesPerPacket

        # O:   Flag to indicate that the decoder has remaining payloads internally
        int moreInternalDecoderFrames

        # O:   Distance between main payload and redundant payload in packets
        int inBandFECOffset

