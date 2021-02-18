cdef extern from "src/SKP_Silk_structs.h" nogil:
    # Noise shaping quantization state
    ctypedef struct SKP_Silk_nsq_state:
        short   xq[2 * 20 * 24]  # Buffer for quantized output signal */
        int   sLTP_shp_Q10[2 * 20 * 24]
        int   sLPC_Q14[20 * 24 / 4 + 32]
        int   sAR2_Q14[16]
        int   sLF_AR_shp_Q12
        int     lagPrev
        int     sLTP_buf_idx
        int     sLTP_shp_buf_idx
        int   rand_seed
        int   prev_inv_gain_Q16
        int     rewhite_flag

    # Struct for Low BitRate Redundant (LBRR) information
    ctypedef struct SKP_SILK_LBRR_struct:
        unsigned char   payload[1024]
        int     nBytes  # Number of bytes in payload
        int     usage  # Tells how the payload should be used as FEC

    # VAD state
    ctypedef struct SKP_Silk_VAD_state:
        int   AnaState[2]  # Analysis filterbank state: 0-8 kHz                       */
        int   AnaState1[2]  # Analysis filterbank state: 0-4 kHz                       */
        int   AnaState2[2]  # Analysis filterbank state: 0-2 kHz                       */
        int   XnrgSubfr[4]  # Subframe energies                                        */
        int   NrgRatioSmth_Q8[4]  # Smoothed energy level in each band                       */
        short   HPstate  # State of differentiator in the lowest band               */
        int   NL[4]  # Noise energy level in each band                          */
        int   inv_NL[4]  # Inverse noise energy level in each band                  */
        int   NoiseLevelBias[4]  # Noise level estimator bias/offset                        */
        int   counter  # Frame counter used in the initial phase                  */

    # Range encoder/decoder state
    ctypedef struct SKP_Silk_range_coder_state:
        int   bufferLength
        int   bufferIx
        unsigned int  base_Q32;
        unsigned int  range_Q16
        int   error
        unsigned char   buffer[1024]  # Buffer containing payload

    # Variable cut-off low-pass filter state */
    ctypedef struct SKP_Silk_LP_state:
        int                   In_LP_State[2]  # Low pass filter state */
        int                   transition_frame_no  # Counter which is mapped to a cut-off frequency */
        int                     mode  # Operating mode, 0: switch down, 1: switch up */

    # Structure for one stage of MSVQ */
    ctypedef struct SKP_Silk_NLSF_CBS:
        const int            nVectors
        const short             *CB_NLSF_Q15
        const short             *Rates_Q5

    # Structure containing NLSF MSVQ codebook */
    ctypedef struct SKP_Silk_NLSF_CB_struct:
        const int             nStages

        # Fields for (de)quantizing */
        const SKP_Silk_NLSF_CBS     *CBStages
        const int               *NDeltaMin_Q15

        # Fields for arithmetic (de)coding */
        const unsigned short            *CDF
        const unsigned short** StartPtr
        const int               *MiddleIx

    # todo 继续
